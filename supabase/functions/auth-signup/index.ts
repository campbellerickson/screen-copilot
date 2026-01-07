// Sign up with email and password
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { supabaseAdmin } from '../_shared/database.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || '';

Deno.serve(async (req) => {
  // Handle CORS
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { email, password, name } = await req.json();

    // Validate input
    if (!email || !password) {
      return errorResponse('Email and password are required', 400);
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return errorResponse('Invalid email format', 400);
    }

    if (password.length < 8 || !/\d/.test(password) || !/[a-zA-Z]/.test(password)) {
      return errorResponse(
        'Password must be at least 8 characters and contain a number and letter',
        400
      );
    }

    // Create user in Supabase Auth
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: email.toLowerCase(),
      password,
      options: {
        data: {
          name: name || null,
        },
      },
    });

    if (authError) {
      if (authError.message.includes('already registered')) {
        return errorResponse('User with this email already exists', 409);
      }
      throw authError;
    }

    if (!authData.user) {
      return errorResponse('Failed to create user', 500);
    }

    // Create user record in our database
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 7);

    const { error: dbError } = await supabaseAdmin.from('users').insert({
      id: authData.user.id,
      email: email.toLowerCase(),
      name: name || null,
      last_login_at: new Date().toISOString(),
    });

    if (dbError) {
      // Rollback: delete auth user if database insert fails
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw dbError;
    }

    // Create trial subscription
    await supabaseAdmin.from('subscriptions').insert({
      user_id: authData.user.id,
      status: 'trial',
      platform: 'ios',
      trial_start_date: new Date().toISOString(),
      trial_end_date: trialEndDate.toISOString(),
    });

    // Get session token
    const { data: sessionData } = await supabase.auth.signInWithPassword({
      email: email.toLowerCase(),
      password,
    });

    return successResponse(
      {
        user: {
          id: authData.user.id,
          email: authData.user.email,
          name: name || null,
          createdAt: authData.user.created_at,
        },
        token: sessionData?.session?.access_token,
        subscription: {
          status: 'trial',
          trialEndDate: trialEndDate.toISOString(),
        },
      },
      201
    );
  } catch (error: any) {
    console.error('Signup error:', error);
    return errorResponse(error.message || 'Failed to create account', 500);
  }
});


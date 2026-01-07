#!/usr/bin/env ts-node

/**
 * Seed script to create a demo user for local development
 * Usage: npx ts-node scripts/seed-demo-user.ts
 */

import { PrismaClient } from '@prisma/client';
import { hashPassword } from '../src/utils/auth';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config({ path: '.env.local' });
dotenv.config();

const prisma = new PrismaClient();

const DEMO_EMAIL = 'demo@screenbudget.local';
const DEMO_PASSWORD = 'Demo123!';
const DEMO_NAME = 'Demo User';

async function seedDemoUser() {
  try {
    console.log('🌱 Seeding demo user...');

    // Check if demo user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: DEMO_EMAIL },
    });

    if (existingUser) {
      console.log('✅ Demo user already exists!');
      console.log(`   Email: ${DEMO_EMAIL}`);
      console.log(`   Password: ${DEMO_PASSWORD}`);
      console.log(`   User ID: ${existingUser.id}`);
      return;
    }

    // Hash password
    const hashedPassword = await hashPassword(DEMO_PASSWORD);

    // Create demo user
    const user = await prisma.user.create({
      data: {
        email: DEMO_EMAIL,
        password: hashedPassword,
        name: DEMO_NAME,
        lastLoginAt: new Date(),
      },
    });

    // Create 7-day trial subscription (extended for demo)
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 30); // 30-day trial for demo

    await prisma.subscription.create({
      data: {
        userId: user.id,
        status: 'trial',
        platform: 'ios',
        trialStartDate: new Date(),
        trialEndDate: trialEndDate,
      },
    });

    console.log('✅ Demo user created successfully!');
    console.log('');
    console.log('📧 Login Credentials:');
    console.log(`   Email: ${DEMO_EMAIL}`);
    console.log(`   Password: ${DEMO_PASSWORD}`);
    console.log(`   User ID: ${user.id}`);
    console.log(`   Trial ends: ${trialEndDate.toLocaleDateString()}`);
    console.log('');
    console.log('💡 You can now use these credentials in the iOS app');

  } catch (error) {
    console.error('❌ Error seeding demo user:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

seedDemoUser();


// Simple test endpoint to verify Vercel is working
import type { VercelRequest, VercelResponse } from '@vercel/node';

export default function handler(req: VercelRequest, res: VercelResponse) {
  return res.status(200).json({
    message: 'Vercel serverless function is working!',
    timestamp: new Date().toISOString(),
    path: req.url,
    method: req.method
  });
}

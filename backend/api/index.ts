// Vercel serverless function entry point
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Import the Express app
let app: any;

async function getApp() {
  if (!app) {
    const serverModule = await import('../src/server');
    app = serverModule.default;
  }
  return app;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const expressApp = await getApp();
  return expressApp(req, res);
}

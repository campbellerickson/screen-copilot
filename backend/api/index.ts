// Vercel serverless function entry point
import app from '../src/server';

// Export the Express app directly
// Vercel will compile TypeScript automatically
export default app;

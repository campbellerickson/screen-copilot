import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import screenTimeRoutes from './routes/screenTime';
import authRoutes from './routes/auth';
import subscriptionRoutes from './routes/subscription';
import weeklyGoalsRoutes from './routes/weeklyGoals';
import breakRemindersRoutes from './routes/breakReminders';
import weeklyInsightsRoutes from './routes/weeklyInsights';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
}));
app.use(morgan('dev'));

// Stripe webhook needs raw body
app.use('/api/v1/subscription/webhook', express.raw({ type: 'application/json' }));

// JSON parsing for all other routes
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging in development
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
  });
}

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/subscription', subscriptionRoutes);
app.use('/api/v1/screen-time', screenTimeRoutes);
app.use('/api/v1/weekly-goals', weeklyGoalsRoutes);
app.use('/api/v1/break-reminders', breakRemindersRoutes);
app.use('/api/v1/weekly-insights', weeklyInsightsRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

// 404 handler (must be after all routes)
app.use(notFoundHandler);

// Global error handler (must be last)
app.use(errorHandler);

// Only start server if not running in Vercel serverless environment
if (process.env.VERCEL !== '1') {
  app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════╗
║  Screen Budget API Server                     ║
║  Port: ${PORT}                                    ║
║  Environment: ${process.env.NODE_ENV || 'development'}                   ║
║  Time: ${new Date().toISOString()}  ║
╚═══════════════════════════════════════════════╝
  `);
  });
}

export default app;

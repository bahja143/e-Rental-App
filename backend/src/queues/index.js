const { Queue, Worker } = require('bullmq');

if (process.env.NODE_ENV === 'test') {
  const noop = async () => {};
  module.exports = {
    emailQueue: {
      add: noop,
      close: noop,
    },
    emailWorker: {
      close: noop,
      on: () => {},
    },
  };
  return;
}

const redisConnection = {
  host: process.env.REDIS_HOST || 'redis',
  port: parseInt(process.env.REDIS_PORT || '6379', 10),
  maxRetriesPerRequest: null,
};

// Create a queue
const emailQueue = new Queue('email', { connection: redisConnection });

// Create a worker
const emailWorker = new Worker('email', async (job) => {
  console.log(`Processing job ${job.id} with data:`, job.data);
  // Simulate email sending
  await new Promise(resolve => setTimeout(resolve, 1000));
  console.log(`Email sent to ${job.data.email}`);
}, {
  connection: redisConnection,
});

// Handle worker events
emailWorker.on('completed', (job) => {
  console.log(`Job ${job.id} completed`);
});

emailWorker.on('failed', (job, err) => {
  console.error(`Job ${job.id} failed with error:`, err.message);
});

module.exports = {
  emailQueue,
  emailWorker,
};

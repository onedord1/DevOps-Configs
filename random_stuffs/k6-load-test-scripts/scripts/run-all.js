const { spawn } = require('child_process');
const path = require('path');
process.env.K6_ENV = 'staging';
require('dotenv').config();

const scenarioFile = path.join(__dirname, '../scenarios/userCreationFlow.js');
const k6Command = `k6 run ${scenarioFile}`;

console.log('--------------------------------------------------');
console.log(`🚀 Starting k6 test run...`);
console.log(`📂 Scenario: ${scenarioFile}`);
console.log(`🌍 Environment: ${process.env.K6_ENV}`);
console.log('--------------------------------------------------');
const k6Process = spawn(k6Command, { shell: true, stdio: 'inherit' });

k6Process.on('close', (code) => {
  console.log('--------------------------------------------------');
  if (code === 0) {
    console.log('✅ k6 test run completed successfully.');
  } else {
    console.error(`❌ k6 test run failed with exit code ${code}.`);
  }
  console.log('--------------------------------------------------');
  process.exit(code);
});
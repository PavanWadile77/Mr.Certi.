const https = require('https');

const payload = JSON.stringify({
  service_id: 'service_mrcerti14',
  template_id: 'template_mrcerti7',
  user_id: 'd0eRJ2yYf_e-ruGhy',
  template_params: {
    to_email: 'test@example.com',
    to_name: 'Test',
    message: 'This is a test message from Mr.Certi debug script.',
    certificate_url: 'http://example.com'
  }
});

const options = {
  hostname: 'api.emailjs.com',
  port: 443,
  path: '/api/v1.0/email/send',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    console.log(`STATUS: ${res.statusCode}`);
    if (res.statusCode >= 400) {
      console.log(`ERROR MESSAGE: ${data}`);
    } else {
      console.log(`SUCCESS: ${data}`);
    }
  });
});

req.on('error', (e) => {
  console.error(`REQUEST ERROR: ${e.message}`);
});

req.write(payload);
req.end();

// Quick test script to verify proxy server is working
const http = require('http');

console.log('Testing proxy server connection...\n');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/health',
  method: 'GET'
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('\nResponse:', data);
    if (res.statusCode === 200) {
      console.log('\n✅ Proxy server is running correctly!');
    } else {
      console.log('\n❌ Proxy server returned an error');
    }
  });
});

req.on('error', (error) => {
  console.error('\n❌ Error connecting to proxy server:');
  console.error(error.message);
  console.log('\n💡 Make sure the proxy server is running:');
  console.log('   cd odoo-proxy-server && npm start');
});

req.end();



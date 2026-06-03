const https = require('https');

const url = 'https://qqevudshpcpahuerhthv.supabase.co/storage/v1/object/authenticated/mock_test/mock_test_json_file/39/1780420722449_demo_mcq.json';
const anonKey = 'sb_publishable_V3mRFNLRC1DNt8n61_Z0CQ_UkQxNo6r';

const options = {
  headers: {
    'apikey': anonKey,
    'Authorization': `Bearer ${anonKey}`
  }
};

https.get(url, options, (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('STATUS:', res.statusCode);
    console.log('BODY:', data);
  });
}).on('error', (err) => {
  console.error('ERROR:', err);
});

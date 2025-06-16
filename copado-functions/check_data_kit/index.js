const jsforce = require('jsforce');

async function run() {
  const conn = new jsforce.Connection({
    instanceUrl: process.env.INSTANCE_URL,
    accessToken: process.env.ACCESS_TOKEN,
  });

  const result = await conn.sobject("DataKit__c")
    .find({ Name: "Sample Data Kit" })
    .limit(1);

  if (result.length > 0) {
    console.log("✅ Sample Data Kit exists.");
  } else {
    console.error("❌ Sample Data Kit not found.");
    process.exit(1); // Fail the step if not found
  }
}

run().catch((error) => {
  console.error("Function Script Error:", error.message);
  process.exit(1);
});

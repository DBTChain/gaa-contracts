import { ethers } from "hardhat";

/**
 * Deploy a Department contract and register it with DBC
 * 
 * Usage: 
 *   DBC_ADDRESS=0x... DEPT_CODE=DBM DEPT_NAME="Department of Budget" AGENCY_NAME="Main Office" AGENCY_OWNER=0x... npx hardhat run scripts/deploy-department.ts
 */
async function main() {
  // Get environment variables or use defaults for local testing
  const dbcAddress = process.env.DBC_ADDRESS;
  const deptCode = process.env.DEPT_CODE || "DBM";
  const deptName = process.env.DEPT_NAME || "Department of Budget and Management";
  const mainAgencyName = process.env.AGENCY_NAME || "Main Office";
  const mainAgencyOwner = process.env.AGENCY_OWNER;

  if (!dbcAddress) {
    console.error("❌ DBC_ADDRESS environment variable is required");
    console.log("Usage: DBC_ADDRESS=0x... npx hardhat run scripts/deploy-department.ts");
    process.exit(1);
  }

  const [deployer] = await ethers.getSigners();
  const agencyOwner = mainAgencyOwner || deployer.address;

  console.log("🏛️  Deploying Department Contract...\n");
  console.log("DBC Address:", dbcAddress);
  console.log("Department Code:", deptCode);
  console.log("Department Name:", deptName);
  console.log("Main Agency Name:", mainAgencyName);
  console.log("Main Agency Owner:", agencyOwner);
  console.log();

  // Deploy Department
  const Department = await ethers.getContractFactory("Department");
  const department = await Department.deploy(
    deptCode,
    deptName,
    mainAgencyName,
    dbcAddress,
    agencyOwner
  );
  await department.waitForDeployment();
  const deptAddress = await department.getAddress();
  
  console.log("✅ Department deployed at:", deptAddress);
  console.log("   Main Agency:", await department.mainAgency());

  // Register with DBC
  console.log("\nRegistering department with DBC...");
  const dbc = await ethers.getContractAt("DBC", dbcAddress);
  await dbc.registerDepartment(deptCode, deptAddress);
  console.log("✅ Department registered with DBC");

  // Summary
  console.log("\n" + "=".repeat(50));
  console.log("📋 DEPARTMENT DEPLOYMENT SUMMARY");
  console.log("=".repeat(50));
  console.log(`
Department Address:  ${deptAddress}
Department Code:     ${deptCode}
Main Agency Address: ${await department.mainAgency()}
Registered with DBC: ✅

To add more agencies to this department:
  DEPT_ADDRESS=${deptAddress} npx hardhat run scripts/add-agency.ts
`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });

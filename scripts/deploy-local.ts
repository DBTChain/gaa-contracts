import { ethers, network } from "hardhat";

/**
 * Full deployment script for local testing
 * Deploys all contracts and sets up a complete test environment
 */
async function main() {
  console.log("🚀 Full Local Deployment for Testing");
  console.log("Network:", network.name);
  console.log("=".repeat(50) + "\n");

  const [deployer, deptOwner1, deptOwner2, agencyOwner1, agencyOwner2] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // ============ Deploy DBC ============
  console.log("\n📦 Deploying DBC Orchestrator...");
  const DBC = await ethers.getContractFactory("DBC");
  const dbc = await DBC.deploy();
  await dbc.waitForDeployment();
  const dbcAddress = await dbc.getAddress();
  console.log("✅ DBC:", dbcAddress);

  // ============ Deploy DPAs ============
  console.log("\n📦 Deploying DPA Contracts...");
  
  const AgencyBudgetDPA = await ethers.getContractFactory("AgencyBudgetDPA");
  const agencyBudgetDPA = await AgencyBudgetDPA.deploy(dbcAddress);
  await agencyBudgetDPA.waitForDeployment();
  console.log("✅ AgencyBudgetDPA:", await agencyBudgetDPA.getAddress());

  const SPFDPA = await ethers.getContractFactory("SPFDPA");
  const spfDPA = await SPFDPA.deploy(dbcAddress);
  await spfDPA.waitForDeployment();
  console.log("✅ SPFDPA:", await spfDPA.getAddress());

  const BESFDPA = await ethers.getContractFactory("BESFDPA");
  const besfDPA = await BESFDPA.deploy(dbcAddress);
  await besfDPA.waitForDeployment();
  console.log("✅ BESFDPA:", await besfDPA.getAddress());

  // ============ Register DPAs ============
  console.log("\n📝 Registering DPAs with DBC...");
  await dbc.registerAgencyBudgetDPA(await agencyBudgetDPA.getAddress());
  await dbc.registerSPFDPA(await spfDPA.getAddress());
  await dbc.registerBESFDPA(await besfDPA.getAddress());
  console.log("✅ All DPAs registered");

  // ============ Deploy Departments ============
  console.log("\n📦 Deploying Department Contracts...");
  
  const Department = await ethers.getContractFactory("Department");
  
  const dbm = await Department.deploy("DBM", "Department of Budget and Management", "DBM Central", dbcAddress, agencyOwner1.address);
  await dbm.waitForDeployment();
  console.log("✅ DBM:", await dbm.getAddress());
  
  const doh = await Department.deploy("DOH", "Department of Health", "DOH Central", dbcAddress, agencyOwner2.address);
  await doh.waitForDeployment();
  console.log("✅ DOH:", await doh.getAddress());

  // ============ Register Departments ============
  console.log("\n📝 Registering Departments with DBC...");
  await dbc.registerDepartment("DBM", await dbm.getAddress());
  await dbc.registerDepartment("DOH", await doh.getAddress());
  console.log("✅ All Departments registered");

  // ============ Set Responsible Departments ============
  console.log("\n📝 Setting Responsible Departments...");
  await dbc.setResponsibleDepartments(await dbm.getAddress(), await dbm.getAddress());
  console.log("✅ DBM set as responsible for Minting and Enactment phases");

  // ============ Summary ============
  console.log("\n" + "=".repeat(60));
  console.log("📋 FULL DEPLOYMENT SUMMARY");
  console.log("=".repeat(60));
  console.log(`
CORE CONTRACTS
--------------
DBC Orchestrator:    ${dbcAddress}
AgencyBudgetDPA:     ${await agencyBudgetDPA.getAddress()}
SPFDPA:              ${await spfDPA.getAddress()}
BESFDPA:             ${await besfDPA.getAddress()}

DEPARTMENTS
-----------
DBM:                 ${await dbm.getAddress()}
  - Main Agency:     ${await dbm.mainAgency()}
DOH:                 ${await doh.getAddress()}
  - Main Agency:     ${await doh.mainAgency()}

CONFIGURATION
-------------
Fiscal Year:         ${await dbc.fiscalYear()}
Current Phase:       Preparation (0)
Responsible Minting: DBM
Responsible Enact:   DBM

READY FOR TESTING! ✅
---------------------
To transition to Minting phase:
  await dbc.transitionToMinting()

To submit an expenditure (in Minting phase):
  await agency.submitExpenditure(...)
`);

  // Return addresses for testing
  return {
    dbc: dbcAddress,
    agencyBudgetDPA: await agencyBudgetDPA.getAddress(),
    spfDPA: await spfDPA.getAddress(),
    besfDPA: await besfDPA.getAddress(),
    dbm: await dbm.getAddress(),
    doh: await doh.getAddress()
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });

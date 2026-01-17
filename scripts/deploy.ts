import { ethers } from "hardhat";

async function main() {
  console.log("🚀 Deploying GAA Contracts System...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // ============ Step 1: Deploy DBC Orchestrator ============
  console.log("Step 1: Deploying DBC Orchestrator...");
  const DBC = await ethers.getContractFactory("DBC");
  const dbc = await DBC.deploy();
  await dbc.waitForDeployment();
  const dbcAddress = await dbc.getAddress();
  console.log("✅ DBC deployed at:", dbcAddress);
  console.log("   Fiscal Year:", await dbc.fiscalYear());
  console.log("   Phase:", await dbc.currentPhase(), "(Preparation)\n");

  // ============ Step 2: Deploy DPA Contracts ============
  console.log("Step 2: Deploying DPA Contracts...");

  const AgencyBudgetDPA = await ethers.getContractFactory("AgencyBudgetDPA");
  const agencyBudgetDPA = await AgencyBudgetDPA.deploy(dbcAddress);
  await agencyBudgetDPA.waitForDeployment();
  console.log("✅ AgencyBudgetDPA deployed at:", await agencyBudgetDPA.getAddress());

  const SPFDPA = await ethers.getContractFactory("SPFDPA");
  const spfDPA = await SPFDPA.deploy(dbcAddress);
  await spfDPA.waitForDeployment();
  console.log("✅ SPFDPA deployed at:", await spfDPA.getAddress());

  const BESFDPA = await ethers.getContractFactory("BESFDPA");
  const besfDPA = await BESFDPA.deploy(dbcAddress);
  await besfDPA.waitForDeployment();
  console.log("✅ BESFDPA deployed at:", await besfDPA.getAddress());

  // ============ Step 3: Register DPAs with DBC ============
  console.log("\nStep 3: Registering DPAs with DBC...");
  
  await dbc.registerAgencyBudgetDPA(await agencyBudgetDPA.getAddress());
  console.log("✅ AgencyBudgetDPA registered");
  
  await dbc.registerSPFDPA(await spfDPA.getAddress());
  console.log("✅ SPFDPA registered");
  
  await dbc.registerBESFDPA(await besfDPA.getAddress());
  console.log("✅ BESFDPA registered");

  // ============ Summary ============
  console.log("\n" + "=".repeat(50));
  console.log("📋 DEPLOYMENT SUMMARY");
  console.log("=".repeat(50));
  console.log(`
DBC Orchestrator:    ${dbcAddress}
AgencyBudgetDPA:     ${await agencyBudgetDPA.getAddress()}
SPFDPA:              ${await spfDPA.getAddress()}
BESFDPA:             ${await besfDPA.getAddress()}

Fiscal Year: ${await dbc.fiscalYear()}
Phase: Preparation (0)

NEXT STEPS:
1. Deploy Department contracts with: npx hardhat run scripts/deploy-department.ts
2. Register departments with DBC
3. Set responsible departments for phase transitions
4. Transition to Minting phase when ready
`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });

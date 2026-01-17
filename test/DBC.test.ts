import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("GAA Contracts", function () {
  this.timeout(600000); // 10 min for viaIR

  async function deployAllFixture() {
    console.log("  Deploying contracts...");
    const [owner, deptOwner, agencyOwner] = await ethers.getSigners();

    // Deploy DBC
    const DBC = await ethers.getContractFactory("DBC");
    const dbc = await DBC.deploy();
    await dbc.waitForDeployment();
    const dbcAddr = await dbc.getAddress();
    console.log("  DBC deployed");

    // Deploy Department
    const Dept = await ethers.getContractFactory("Department");
    const dept = await Dept.deploy("DBM", "Dept of Budget", "Main Office", dbcAddr, agencyOwner.address);
    await dept.waitForDeployment();
    console.log("  Department deployed");

    // Deploy AgencyBudgetDPA
    const AgencyDPA = await ethers.getContractFactory("AgencyBudgetDPA");
    const agencyDPA = await AgencyDPA.deploy(dbcAddr);
    await agencyDPA.waitForDeployment();
    console.log("  AgencyBudgetDPA deployed");

    return { dbc, dept, agencyDPA, owner, agencyOwner };
  }

  describe("DBC Core", function () {
    it("Should deploy with correct initial state", async function () {
      const { dbc, owner } = await loadFixture(deployAllFixture);
      
      expect(await dbc.owner()).to.equal(owner.address);
      expect(await dbc.currentPhase()).to.equal(0); // Preparation
      expect(await dbc.fiscalYear()).to.equal(2026);
      expect(await dbc.paused()).to.equal(false);
      console.log("  ✓ DBC state verified");
    });

    it("Should allow pause/unpause", async function () {
      const { dbc, owner } = await loadFixture(deployAllFixture);
      
      await dbc.pause();
      expect(await dbc.paused()).to.equal(true);
      
      await dbc.unpause();
      expect(await dbc.paused()).to.equal(false);
      console.log("  ✓ Pausable verified");
    });

    it("Should register department and DPA", async function () {
      const { dbc, dept, agencyDPA } = await loadFixture(deployAllFixture);
      
      // Register department
      await dbc.registerDepartment("DBM", await dept.getAddress());
      expect(await dbc.getDepartmentCount()).to.equal(1);
      
      // Register DPA
      await dbc.registerAgencyBudgetDPA(await agencyDPA.getAddress());
      const [registeredDPA] = await dbc.getCurrentDPAs();
      expect(registeredDPA).to.equal(await agencyDPA.getAddress());
      
      console.log("  ✓ Registration verified");
    });

    it("Should transition phases correctly through Department", async function () {
      const { dbc, dept, owner } = await loadFixture(deployAllFixture);
      const deptAddr = await dept.getAddress();
      
      // Register and set responsible departments (DBM for both minting and enactment)
      await dbc.registerDepartment("DBM", deptAddr);
      await dbc.setResponsibleDepartments(deptAddr, deptAddr);
      
      // Prep -> Minting (owner can call directly on DBC)
      expect(await dbc.currentPhase()).to.equal(0); // Preparation
      await dbc.transitionToMinting();
      expect(await dbc.currentPhase()).to.equal(1); // Minting
      console.log("  ✓ Prep -> Minting (via DBC)");
      
      // Minting -> Enactment (must go through Department as responsible)
      // Note: owner deployed dept, so owner is dept owner
      await dept.transitionToEnactment();
      expect(await dbc.currentPhase()).to.equal(2); // Enactment
      console.log("  ✓ Minting -> Enactment (via Department)");
      
      // Enactment -> Finality (must go through Department as responsible)
      await dept.transitionToFinality();
      expect(await dbc.currentPhase()).to.equal(3); // Finality
      console.log("  ✓ Enactment -> Finality (via Department)");
      
      // Finality -> Preparation + new FY (must go through Department)
      await dept.completeAndReset();
      expect(await dbc.currentPhase()).to.equal(0); // Preparation
      expect(await dbc.fiscalYear()).to.equal(2027);
      console.log("  ✓ Finality -> Preparation (via Department)");
      
      console.log("  ✓ Full phase lifecycle verified");
    });
  });

  describe("Department", function () {
    it("Should create main agency on deploy", async function () {
      const { dept, agencyOwner } = await loadFixture(deployAllFixture);
      
      expect(await dept.code()).to.equal("DBM");
      expect(await dept.getAgencyCount()).to.equal(1);
      
      const mainAgency = await dept.mainAgency();
      expect(mainAgency).to.not.equal(ethers.ZeroAddress);
      
      console.log("  ✓ Department verified");
    });
  });
});

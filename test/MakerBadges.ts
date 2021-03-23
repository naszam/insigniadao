// MakerBadges.ts

import { expect } from "chai"
import { ethers, web3 } from "hardhat"

import { MakerBadges, MakerBadges__factory } from "../typechain"

import { MerkleTree } from "merkletreejs"

require("chai").use(require("chai-as-promised")).should()

describe("MakerBadges", () => {
  let signers: any
  let makerbadges: MakerBadges

  const template_name = "Beginner"
  const template_description = "Beginner Template"
  const template_image = "badge.png"
  const template_name2 = "Intermediate"
  const template_description2 = "Intermediate Template"
  const template_image2 = "badge2.png"
  const templateId = "0"
  const index1 = "0"
  const index2 = "1"

  const DEFAULT_ADMIN_ROLE = ethers.constants.HashZero
  const TEMPLATER_ROLE = web3.utils.soliditySha3("TEMPLATER_ROLE")
  const PAUSER_ROLE = web3.utils.soliditySha3("PAUSER_ROLE")

  const name = "MakerBadges"
  const symbol = "MAKER"
  const baseURI = "https://badges.makerdao.com/token/"
  const baseURI2 = "https://badegs.com/token/"
  const tokenURI = "ipfs.js"

  beforeEach(async () => {
    const [deployer, owner, templater, redeemer, random] = await ethers.getSigners()
    signers = { deployer, templater, redeemer, random }
    const MakerBadgesFactory = (await ethers.getContractFactory("MakerBadges", deployer)) as MakerBadges__factory
    makerbadges = await MakerBadgesFactory.deploy()
  })

  // Check that the deployer is set as the only admin when the contract is deployed
  // Check that the deployer is set as the only templater when the contract is deployed
  // Check that the deployer is set as the only pauser when the contract is deployed
  describe("Setup", async () => {
    it("deployer has the default admin role", async () => {
      const admin_count = await makerbadges.getRoleMemberCount(DEFAULT_ADMIN_ROLE)
      admin_count.toString().should.equal("1")
      const def_admin = await makerbadges.getRoleMember(DEFAULT_ADMIN_ROLE, 0)
      def_admin.should.equal(signers.deployer.address)
    })

    it("deployer has the templater role", async () => {
      const templater_count = await makerbadges.getRoleMemberCount(TEMPLATER_ROLE)
      templater_count.toString().should.equal("1")
      const templater = await makerbadges.getRoleMember(TEMPLATER_ROLE, 0)
      templater.should.equal(signers.deployer.address)
    })

    it("deployer has the pauser role", async () => {
      const pauser_count = await makerbadges.getRoleMemberCount(PAUSER_ROLE)
      pauser_count.toString().should.equal("1")
      const pauser = await makerbadges.getRoleMember(PAUSER_ROLE, 0)
      pauser.should.equal(signers.deployer.address)
    })
  })
})
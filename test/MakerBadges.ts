// MakerBadges.ts

import { expect } from "chai"
import { ethers, web3 } from "hardhat"

import { MakerBadges, MakerBadges__factory } from "../typechain"

import { MerkleTree } from "merkletreejs"

const { soliditySha3 } = web3.utils
const { HashZero, AddressZero } = ethers.constants

describe("MakerBadges", () => {
  let signers: any
  let makerbadges: MakerBadges
  let logs: any
  let tree: any

  const template_name = "Accrue 1 Dai from DSR"
  const template_description = "Accrue 1 Dai from the Dai Savings Rate"
  const template_image = "https://ipfs.io/ipfs/ipfs_hash"
  const template_name2 = "Earn in DSR for 3 months"
  const template_description2 = "Lock 10 Dai in the Dai Savings Rate for 3 months"
  const template_image2 = "https://ipfs.io/ipfs/ipfs_hash2"
  const templateId = "0"
  const index1 = "0"

  const DEFAULT_ADMIN_ROLE = HashZero
  const TEMPLATER_ROLE = soliditySha3("TEMPLATER_ROLE")
  const PAUSER_ROLE = soliditySha3("PAUSER_ROLE")

  const baseURI2 = "https://badges.com/token/"
  const tokenURI = "ipfs_hash"

  beforeEach(async () => {
    const [deployer, templater, redeemer, random] = await ethers.getSigners()
    signers = { deployer, templater, redeemer, random }
    const MakerBadgesFactory = (await ethers.getContractFactory("MakerBadges", deployer)) as MakerBadges__factory
    makerbadges = await MakerBadgesFactory.deploy()
  })

  // Check that the deployer is set as the only admin when the contract is deployed
  // Check that the deployer is set as the only templater when the contract is deployed
  // Check that the deployer is set as the only pauser when the contract is deployed
  describe("Setup", async () => {
    it("deployer has the default admin role", async () => {
      expect(await makerbadges.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.eq("1")
      expect(await makerbadges.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.be.eq(signers.deployer.address)
    })
    it("deployer has the templater role", async () => {
      expect(await makerbadges.getRoleMemberCount(TEMPLATER_ROLE)).to.be.eq("1")
      expect(await makerbadges.getRoleMember(TEMPLATER_ROLE, 0)).to.be.eq(signers.deployer.address)
    })
    it("deployer has the pauser role", async () => {
      expect(await makerbadges.getRoleMemberCount(PAUSER_ROLE)).to.be.eq("1")
      expect(await makerbadges.getRoleMember(PAUSER_ROLE, 0)).to.be.eq(signers.deployer.address)
    })
  })

  // Check ERC721 metadata
  describe("ERC721 metadata", async () => {
    it("has a name", async () => {
      expect(await makerbadges.name()).to.be.eq("MakerBadges")
    })
    it("has a symbol", async () => {
      expect(await makerbadges.symbol()).to.be.eq("MAKER")
    })
    it("has a baseURI", async () => {
      expect(await makerbadges.baseURI()).to.be.eq("https://badges.makerdao.com/token/")
    })
    it("return a baseURI + tokenURI for tokenId", async () => {
      const hash0 = soliditySha3(signers.redeemer.address)
      const hash1 = soliditySha3(signers.deployer.address)
      const hash2 = soliditySha3(signers.templater.address)
      const hash3 = soliditySha3(signers.random.address)
      const leaves = [hash0, hash1, hash2, hash3]
      const merkleTree = new MerkleTree(leaves, soliditySha3, { sortPairs: true })

      const root = merkleTree.getHexRoot()
      const rootHashes = [root, HashZero, HashZero, HashZero]
      const leaf = soliditySha3(signers.redeemer.address)
      const proof = merkleTree.getHexProof(leaf)
      await makerbadges.connect(signers.deployer).setRootHashes(rootHashes)
      await makerbadges.connect(signers.deployer).createTemplate(template_name, template_description, template_image)
      await makerbadges.connect(signers.redeemer).activateBadge(proof, templateId, tokenURI)
      const tokenId = await makerbadges.tokenOfOwnerByIndex(signers.redeemer.address, index1)
      expect(await makerbadges.tokenURI(tokenId)).to.be.eq("https://badges.makerdao.com/token/" + tokenURI)
    })
    it("return an updated baseURI", async () => {
      await makerbadges.connect(signers.deployer).setBaseURI(baseURI2)
      expect(await makerbadges.baseURI()).to.be.eq(baseURI2)
    })
    it("reverts when querying metadata for non existent tokenId", async () => {
      await expect(makerbadges.connect(signers.random).tokenURI("0")).to.be.revertedWith(
        "ERC721Metadata: URI query for nonexistent token",
      )
    })
  })

  // Check createTemplate for success when a templater is trying to create a new template
  // Check createTemplate for sucessfully emit event when the template is created
  // Check createTemplate for failure when a random address try to create a new template
  describe("createTemplate", async () => {
    it("templater should be able to create a template", async () => {
      await makerbadges.connect(signers.deployer).createTemplate(template_name, template_description, template_image)
      const receipt = await makerbadges.templates(templateId)
      expect(receipt[0]).to.be.eq(template_name)
      expect(receipt[1]).to.be.eq(template_description)
      expect(receipt[2]).to.be.eq(template_image)
      expect(await makerbadges.getTemplatesCount()).to.be.eq("1")
    })
    it("should emit the appropriate event when a template is created", async () => {
      await expect(
        makerbadges.connect(signers.deployer).createTemplate(template_name, template_description, template_image),
      )
        .to.emit(makerbadges, "NewTemplate")
        .withArgs(templateId, template_name, template_description, template_image)
    })
    it("should not allow create a new template from random user", async () => {
      await expect(
        makerbadges.connect(signers.random).createTemplate(template_name, template_description, template_image),
      ).to.be.revertedWith("MakerBadges: caller is not a template owner")
    })
  })
  // Check updateTemplate for success when a templater try to update a template
  // Check updateTemplate for sucessfully emit event when the template is updated
  // Check updateTemplate for failure when a random address try to update a template
  describe("updateTemplate", async () => {
    beforeEach(async () => {
      await makerbadges.connect(signers.deployer).createTemplate(template_name, template_description, template_image)
    })
    it("templaters should be able to update a template", async () => {
      await makerbadges
        .connect(signers.deployer)
        .updateTemplate(templateId, template_name2, template_description2, template_image2)
      const receipt = await makerbadges.templates(templateId)
      expect(receipt[0]).to.be.eq(template_name2)
      expect(receipt[1]).to.be.eq(template_description2)
      expect(receipt[2]).to.be.eq(template_image2)
      expect(await makerbadges.getTemplatesCount()).to.be.eq("1")
    })
    it("should emit the appropriate event when a template is updated", async () => {
      await expect(
        makerbadges
          .connect(signers.deployer)
          .updateTemplate(templateId, template_name2, template_description2, template_image2),
      )
        .to.emit(makerbadges, "TemplateUpdated")
        .withArgs(templateId, template_name2, template_description2, template_image2)
    })
    it("should not allow to update a template form random user", async () => {
      await expect(
        makerbadges
          .connect(signers.random)
          .updateTemplate(templateId, template_name2, template_description2, template_image2),
      ).to.be.revertedWith("MakerBadges: caller is not a template owner")
    })
  })
  // Check activateBadge for success when a redeemer checked offchain activate a badge
  // Check activateBadge for sucessfully emit event when the badge is activated
  // Check activateBadge for failure when a random address try to activate a badge
  describe("activateBadge", async () => {
    beforeEach(async () => {
      const hash0 = soliditySha3(signers.redeemer.address)
      const hash1 = soliditySha3(signers.deployer.address)
      const hash2 = soliditySha3(signers.templater.address)
      const hash3 = soliditySha3(signers.random.address)
      const leaves = [hash0, hash1, hash2, hash3]
      const merkleTree = new MerkleTree(leaves, soliditySha3, { sortPairs: true })
      const root = merkleTree.getHexRoot()
      const rootHashes = [root, HashZero, HashZero, HashZero]
      const leaf = soliditySha3(signers.redeemer.address)
      const proof = merkleTree.getHexProof(leaf)
      await makerbadges.connect(signers.deployer).setRootHashes(rootHashes)
      await makerbadges.connect(signers.deployer).createTemplate(template_name, template_description, template_image)
      const receipt = await makerbadges.connect(signers.redeemer).activateBadge(proof, templateId, tokenURI)
      tree = { proof }
      logs = { receipt }
    })
    it("should allow redeemers checked offchain to activate a badge", async () => {
      const tokenId = await makerbadges.tokenOfOwnerByIndex(signers.redeemer.address, index1)
      expect(await makerbadges.getBadgeRedeemer(tokenId)).to.be.eq(signers.redeemer.address)
      expect(await makerbadges.getBadgeTemplate(tokenId)).to.be.eq(templateId)
      expect(await makerbadges.templateQuantities(templateId)).to.be.eq("1")
    })
    it("should emit the appropriate event when a badge is activated", async () => {
      const tokenId = await makerbadges.tokenOfOwnerByIndex(signers.redeemer.address, index1)
      expect(logs.receipt).to.emit(makerbadges, "BadgeActivated").withArgs(tokenId, templateId, tokenURI)
      expect(logs.receipt).to.emit(makerbadges, "Transfer").withArgs(AddressZero, signers.redeemer.address, tokenId)
    })
    it("should revert when templeteId does not exist", async () => {
      await expect(
        makerbadges.connect(signers.redeemer).activateBadge(tree.proof, templateId + 1, tokenURI),
      ).to.be.revertedWith("MakerBadges: no template with that id")
    })
    it("should not allow to activate a new badge form random user", async () => {
      await expect(
        makerbadges.connect(signers.random).activateBadge(tree.proof, templateId, tokenURI),
      ).to.be.revertedWith("MakerBadges: caller is not a redeemer")
    })
    it("redeemer should not be able to activate the same badge twice", async () => {
      await expect(
        makerbadges.connect(signers.redeemer).activateBadge(tree.proof, templateId, tokenURI),
      ).to.be.revertedWith("ERC721: token already minted")
    })
  })
})

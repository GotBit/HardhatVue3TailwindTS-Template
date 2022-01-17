import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { ERC1155Extended } from '../../../typechain'

describe('ERC1155Extended', function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    minter: SignerWithAddress,
    creator: SignerWithAddress
  let erc1155Extended: ERC1155Extended

  const uri = 'test.uri'

  before(async () => {
    ;[owner, addr1, addr2, addr3, minter, creator] = await ethers.getSigners()

    const erc1155ExtendedFactory = await ethers.getContractFactory('ERC1155Extended')
    erc1155Extended = await erc1155ExtendedFactory.deploy('Test', 'TST', owner.address)
  })

  it('should gives creator role', async () => {
    await erc1155Extended.grantRoleCreator(creator.address)
    await erc1155Extended.connect(creator).create(uri)
    await erc1155Extended.revokeRoleCreator(creator.address)
    await expect(erc1155Extended.connect(creator).create(uri)).to.be.reverted
    await erc1155Extended.grantRoleCreator(creator.address)
  })

  it('should creates new id', async () => {
    await erc1155Extended.connect(creator).create(uri)
    expect(await erc1155Extended.uris(2)).to.be.eq(uri)
  })

  it('should gives minter roles', async () => {
    await erc1155Extended.grantRoleMinter(minter.address)
    await erc1155Extended.connect(minter).mint(addr1.address, 1, 1)
    await erc1155Extended.revokeRoleMinter(minter.address)
    await expect(erc1155Extended.connect(minter).mint(addr1.address, 1, 1)).to.be.reverted
    await erc1155Extended.grantRoleMinter(minter.address)
  })

  it('should restrict the creation new id for non creator', async () => {
    await expect(erc1155Extended.connect(addr1).create(uri)).to.be.reverted
    await expect(erc1155Extended.connect(minter).create(uri)).to.be.reverted
    await expect(erc1155Extended.connect(owner).create(uri)).to.be.reverted
  })

  it('should mint one token', async () => {
    await erc1155Extended.connect(minter).mint(addr2.address, 1, 1)
    expect(await erc1155Extended.balanceOf(addr2.address, 1)).to.be.eq(1)
  })

  it('should mint batch of tokens', async () => {
    await erc1155Extended.connect(creator).create(uri)
    await erc1155Extended.connect(minter).mintBatch(addr3.address, [1, 2], [88901, 8982])
    expect(await erc1155Extended.balanceOf(addr3.address, 1)).to.be.eq(88901)
    expect(await erc1155Extended.balanceOf(addr3.address, 2)).to.be.eq(8982)
  })

  it('should gives correct uri', async () => {
    expect(await erc1155Extended.uri(1)).to.be.eq(uri)
  })

  it('should deny minting of fake id', async () => {
    await expect(erc1155Extended.connect(minter).mint(minter.address, 10, 2)).to.be
      .reverted
  })

  it('should gives correct info about token id and all tokens ', async () => {
    const infoBundle = await erc1155Extended.infoBundleForUser(addr3.address)
    let ind = 1
    const balances = [88901, 8982, 0]
    for (const tokenInfo of infoBundle) {
      expect(tokenInfo.id).to.be.equal(ind)
      expect(tokenInfo.uri).to.be.equal(uri)
      expect(tokenInfo.uri).to.be.equal(await erc1155Extended.infoBundleForToken(ind))
      expect(tokenInfo.balance).to.be.equal(balances[ind - 1])
      ind += 1
    }
    await expect(erc1155Extended.infoBundleForToken(34)).to.be.reverted
  })
})

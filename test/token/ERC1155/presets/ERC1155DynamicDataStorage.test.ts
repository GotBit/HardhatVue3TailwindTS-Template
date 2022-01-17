import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'
import { ERC1155DynamicDataStorage } from '../../../../typechain'

describe('ERC1155DynamicDataStorage', function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    minter: SignerWithAddress,
    creator: SignerWithAddress,
    upgrader: SignerWithAddress
  let erc1155DynamicDataStorage: ERC1155DynamicDataStorage

  const uri = 'test.uri'

  const data = {
    name_: 'Test name',
    power: 3,
    rarity: 'Rare',
  }

  const dynamicProps = {
    name: 'level',
    min: 1,
    max: 4,
  }

  before(async () => {
    ;[owner, addr1, addr2, addr3, minter, creator, upgrader] = await ethers.getSigners()

    const erc1155DynamicDataStorageFactory = await ethers.getContractFactory(
      'ERC1155DynamicDataStorage'
    )
    erc1155DynamicDataStorage = await erc1155DynamicDataStorageFactory.deploy(
      'Test',
      'TST',
      owner.address
    )

    await erc1155DynamicDataStorage.grantRoleUpgrader(upgrader.address)
  })

  it('should gives creator role', async () => {
    await erc1155DynamicDataStorage.grantRoleCreator(creator.address)

    await erc1155DynamicDataStorage
      .connect(creator)
      ['create(string,(string,uint256,string),(string,uint256,uint256))'](
        uri,
        data,
        dynamicProps
      )
    await erc1155DynamicDataStorage.revokeRoleCreator(creator.address)
    await expect(
      erc1155DynamicDataStorage
        .connect(creator)
        ['create(string,(string,uint256,string),(string,uint256,uint256))'](
          uri,
          data,
          dynamicProps
        )
    ).to.be.reverted
    await erc1155DynamicDataStorage.grantRoleCreator(creator.address)
  })

  it('should creates new id', async () => {
    await erc1155DynamicDataStorage
      .connect(creator)
      ['create(string,(string,uint256,string),(string,uint256,uint256))'](
        uri,
        data,
        dynamicProps
      )

    expect(await erc1155DynamicDataStorage.uris(2)).to.be.eq(uri)
    const dataIncoming = await erc1155DynamicDataStorage.datas(2)

    expect(dataIncoming.name_).be.equal(data.name_)
    expect(dataIncoming.power).be.equal(data.power)
    expect(dataIncoming.rarity).be.equal(data.rarity)

    const dynamicPropsIncoming = await erc1155DynamicDataStorage.dynamicProps(2)
    expect(dynamicPropsIncoming.name).to.be.equal(dynamicProps.name)
    expect(dynamicPropsIncoming.min).to.be.equal(dynamicProps.min)
    expect(dynamicPropsIncoming.max).to.be.equal(dynamicProps.max)
  })

  it('should gives minter roles', async () => {
    await erc1155DynamicDataStorage.grantRoleMinter(minter.address)
    await erc1155DynamicDataStorage
      .connect(minter)
      ['mint(address,uint256,uint256,uint256)'](addr1.address, 1, 1, 1)

    await erc1155DynamicDataStorage.revokeRoleMinter(minter.address)
    await expect(
      erc1155DynamicDataStorage
        .connect(minter)
        ['mint(address,uint256,uint256,uint256)'](addr1.address, 1, 1, 1)
    ).to.be.reverted
    await erc1155DynamicDataStorage.grantRoleMinter(minter.address)
  })

  it('should restrict the creation new id for non creator', async () => {
    await expect(
      erc1155DynamicDataStorage
        .connect(addr1)
        ['create(string,(string,uint256,string),(string,uint256,uint256))'](
          uri,
          data,
          dynamicProps
        )
    ).to.be.reverted

    await expect(
      erc1155DynamicDataStorage
        .connect(minter)
        ['create(string,(string,uint256,string),(string,uint256,uint256))'](
          uri,
          data,
          dynamicProps
        )
    ).to.be.reverted

    await expect(
      erc1155DynamicDataStorage
        .connect(owner)
        ['create(string,(string,uint256,string),(string,uint256,uint256))'](
          uri,
          data,
          dynamicProps
        )
    ).to.be.reverted
  })

  it('should mint one token', async () => {
    await erc1155DynamicDataStorage
      .connect(minter)
      ['mint(address,uint256,uint256,uint256)'](addr2.address, 1, 1, 2)
    expect(await erc1155DynamicDataStorage.balanceOf(addr2.address, 1)).to.be.eq(1)
  })

  it('should deny mint with invalid dynamic init value', async () => {
    await expect(
      erc1155DynamicDataStorage
        .connect(minter)
        ['mint(address,uint256,uint256,uint256)'](addr2.address, 1, 1, 5)
    ).to.be.reverted

    await expect(
      erc1155DynamicDataStorage
        .connect(minter)
        ['mint(address,uint256,uint256,uint256)'](addr2.address, 1, 1, 0)
    ).to.be.reverted
  })

  it('should mint batch of tokens', async () => {
    const amounts = [88901, 8982]
    await erc1155DynamicDataStorage
      .connect(minter)
      ['mintBatch(address,uint256[],uint256[],uint256[])'](
        addr3.address,
        [1, 2],
        amounts,
        [1, 2]
      )
    expect(await erc1155DynamicDataStorage.balanceOf(addr3.address, 1)).to.be.eq(
      amounts[0]
    )
    expect(await erc1155DynamicDataStorage.balanceOf(addr3.address, 2)).to.be.eq(
      amounts[1]
    )

    expect(
      await erc1155DynamicDataStorage.dynamicBalances(addr3.address, 1, 1)
    ).to.be.equal(amounts[0])
    expect(
      await erc1155DynamicDataStorage.dynamicBalances(addr3.address, 2, 2)
    ).to.be.equal(amounts[1])
  })

  it('should gives correct uri', async () => {
    expect(await erc1155DynamicDataStorage.uri(1)).to.be.eq(uri)
  })

  it('should deny minting of fake id', async () => {
    await expect(
      erc1155DynamicDataStorage
        .connect(minter)
        ['mint(address,uint256,uint256,uint256)'](minter.address, 10, 2, 2)
    ).be.reverted
  })

  it('should gives correct info about token id and all tokens ', async () => {
    const amounts = [88901, 8982]

    await erc1155DynamicDataStorage.connect(upgrader).upgrade(addr3.address, 1, 1, 3, 10)

    const infoBundle = await erc1155DynamicDataStorage.infoBundleForUserExtra(
      addr3.address
    )

    const balances = {
      1: {
        1: amounts[0] - 10,
        2: 0,
        3: 10,
        4: 0,
      },
      2: {
        1: 0,
        2: amounts[1],
        3: 0,
        4: 0,
      },
    }
    for (const info of infoBundle) {
      for (const dyn of info.dynamics) {
        expect(dyn.balance).to.be.equal(
          balances[info.id.toNumber() as 1 | 2][dyn.value.toNumber() as 1 | 2 | 3 | 4]
        )
      }
    }

    const infoToken = await erc1155DynamicDataStorage.infoBundleForTokenExtra(1)
    expect(infoToken.uri_).to.be.equal(uri)
    expect(infoToken.data_.name_).to.be.equal(data.name_)
    expect(infoToken.data_.power).to.be.equal(data.power)
    expect(infoToken.data_.rarity).to.be.equal(data.rarity)
    expect(infoToken.dynamicProps_.name).to.be.equal(dynamicProps.name)
    expect(infoToken.dynamicProps_.min).to.be.equal(dynamicProps.min)
    expect(infoToken.dynamicProps_.max).to.be.equal(dynamicProps.max)
  })
})

// @ts-ignore
import { expect } from "chai"
import { ethers } from "hardhat"

describe("Counter", function () {
  it("Should return default number of Counter", async function () {
    const Counter = await ethers.getContractFactory("Counter")
    const counter = await Counter.deploy()
    await counter.deployed()

    expect(await counter.number()).to.eq(0)
  })
})
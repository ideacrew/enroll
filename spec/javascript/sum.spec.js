import chai, { expect } from 'chai'
import chaiDom from 'chai-dom'
import sinonChai from 'sinon-chai'
chai.use(chaiDom)
chai.use(sinonChai)


describe('Calculator', function() {
  it('should return 3 for 1 + 2', () => {
    expect(1+2).to.equal(3);
  });

});
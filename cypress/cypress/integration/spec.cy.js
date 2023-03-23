describe('Octopub', () => {
    it('Should display header', () => {
    	cy.visit('/')
        cy.get('#header').should('not.be.empty')
    })
})
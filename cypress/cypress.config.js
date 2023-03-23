const { defineConfig } = require('cypress')

module.exports = defineConfig({
    e2e: {
        specPattern: "cypress/integration",
        baseUrl: "https://europe-azure-web-app--cac--development-wa.azurewebsites.net/",
        reporter: "mochawesome",
        reporterOptions: {
            "charts": true,
            "overwrite": false,
            "html": true,
            "json": false,
            "reportDir": "."
        },
        supportFile: false
    },
});
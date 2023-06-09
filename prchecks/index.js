#!/usr/bin/env node

/*
    This script provides an example of parsing and validating the Octopus Configuration Language (OCL) file
    defining the deployment process in a Config-as-Code (CaC) enabled project. This allows you to ensure any
    changes to a deployment process meet your minimum custom requirements.

    The workflow this script enables is:
    1. Create a new branch in your CaC enabled project.
    2. Edit the deployment process.
    3. Create a pull request to the main branch.
    4. Have the git platform run this script as part of the pull request.
    5. Pass or fail the pull request based on the rules in this script.

    A sample GitHub Actions Workflow is saved in the .github/workflows/prvalidation.yaml file.
 */

import {Lexer, NodeType, Parser, TokenType} from "@octopusdeploy/ocl"
import * as fs from "fs";
import * as path from "path";

const FirstStepName = "\"Manual Intervention\""
const ManualInterventionType = "\"Octopus.Manual\""

/*
    Ensure the path to the directory holding the deployment_process.ocl file was passed as an argument (with the
    other 2 arguments being the node executable itself and the name of this script file).
 */
if (process.argv.length !== 3) {
    console.log("Pass the directory holding the deployment_process.ocl file as the first argument")
    process.exit(1)
}

// Read the deployment process OCL file
fs.readFile(path.join(process.argv[2], 'deployment_process.ocl'), 'utf8', (err, data) => {
    // Any error reading the file fails the script
    if (err) {
        console.error(err)
        process.exit(1)
    }

    // These come from the @octopusdeploy/ocl dependency
    const lexer = new Lexer(data)
    const parser = new Parser(lexer)
    const ast = parser.getAST()

    // Test that we have any steps at all
    if (ast.length === 0) {
        console.log("Deployment process can not be empty")
        process.exit(1)
    }

    // Test that the first step has the correct name
    if (!ast[0].children.some(c =>
        c.type === NodeType.ATTRIBUTE_NODE &&
            c.name.value === "name" &&
            c.value.value.value === FirstStepName)) {                   // You do need to dig right down to find the value of an attribute
        console.log("First step must be called " + FirstStepName)
        process.exit(1)
    }

    // Test that the first step is of the correct type
    let foundManualIntervention = false
    for (const block of ast[0].children) {
        if (block.name.value === "action") {
            for (const actionBlock of block.children) {
                if (actionBlock.name.value === "action_type" &&
                    actionBlock.value.value.value === ManualInterventionType) {
                    foundManualIntervention = true
                    break
                }
            }
        }
    }

    if (!foundManualIntervention) {
        console.log("First step must be a manual intervention step")
        process.exit(1)
    }

    console.log("All tests passed!")
    process.exit(0)
})

function blockEquals(a, b) {
    if (a.type !== NodeType.BLOCK_NODE || b.type !== NodeType.BLOCK_NODE) {
        return false
    }

    if (a.name.type !== b.name.type) {
        return false
    }

    if (a.name.value !== b.name.value) {
        return false
    }

    if (a.children.length !== b.children.length) {
        return false
    }

    for (let i = 0; i < a.children.length; ++i) {
        if (a.children[i].type === NodeType.BLOCK_NODE) {
            if (!blockEquals(a.children[i], b.children[i])) {
                return false
            }
        }

        if (a.children[i].type === NodeType.ATTRIBUTE_NODE) {
            if (!attributeEquals(a.children[i], b.children[i])) {
                return false
            }
        }
    }
}

function attributeEquals(a, b) {
    if (a.type !== NodeType.ATTRIBUTE_NODE || b.type !== NodeType.ATTRIBUTE_NODE) {
        return false
    }

    if (a.name.type !== b.name.type) {
        return false
    }

    if (a.name.value !== b.name.value) {
        return false
    }

    if (a.value.value.value !== b.value.value.value) {
        return false
    }

    return true
}
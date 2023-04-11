#!/usr/bin/env node

import {Lexer, NodeType, Parser, TokenType} from "@octopusdeploy/ocl"
import * as fs from "fs";
import * as path from "path";

const FirstStepName = "\"Manual Intervention Required\""
const ManualInterventionType = "\"Octopus.Manual\""

if (process.argv.length !== 3) {
    console.log("Pass the directory holding the deployment_process.ocl file as the first argument")
    process.exit(1)
}

fs.readFile(path.join(process.argv[2], 'deployment_process.ocl'), 'utf8', (err, data) => {
    if (err) {
        console.error(err)
        process.exit(1)
    }

    const lexer = new Lexer(data)
    const parser = new Parser(lexer)
    const ast = parser.getAST()

    // Test that we have any steps
    if (ast.length === 0) {
        console.log("Deployment process can not be empty")
        process.exit(1)
    }

    // Test that the first step has the correct name
    if (!ast[0].children.some(c =>
        c.type === NodeType.ATTRIBUTE_NODE &&
            c.name.value === "name" &&
            c.value.value.value === FirstStepName)) {
        console.log("First step must be called " + FirstStepName)
        process.exit(1)
    }

    // Test that the first step is of the correct type
    let foundManualIntervention = false
    for (const block of ast[0].children) {
        if (block.name.value === "action") {
            for (const actionBlock of block.children) {
                if (actionBlock.name.value === "action_type" && actionBlock.value.value.value === ManualInterventionType) {
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

#!/bin/sh

echo instalando node mais atual
nvm install --lts

cat << EOF > package.json
{
  "name": "projeto",
  "version": "1.0.0",
  "description": "",
  "type": "module",
  "author": "Prover",
  "main": "./src/server.js",
  "scripts": {
    "start": "npx prisma migrate deploy && node ./src/server.js",
    "start:dev": "nodemon",
    "migration": "npx prisma migrate dev",
    "prisma:push": "echo não use o push!! use o npm run migration",
    "prisma:pull": "echo não use o pull!! use o npm run migration",
    "prisma:generate": "prisma generate",
    "postinstall": "prisma generate",
    "test:create-prisma-environment": "npm link ./prisma/vitest-environment-prisma",
    "test:install-prisma-environment": "npm link vitest-environment-prisma",
    "pretest:e2e": "npm run test:create-prisma-environment && npm run test:install-prisma-environment",
    "test": "vitest run -c vitest.unit.config.js",
    "test:e2e": "vitest run -c vitest.e2e.config.js",
    "test:e2e:watch": "vitest -c vitest.e2e.config.js",
    "test:coverage": "vitest run --coverage"
  },
  "keywords": [],
  "license": "ISC"
}
EOF

echo instalando dependencias 

npm i cors express helmet jsonwebtoken dotenv

npm i -D eslint eslint-config-standard eslint-plugin-import eslint-plugin-n eslint-plugin-promise vitest supertest nodemon prisma

mkdir src
mkdir test
mkdir .vscode

echo criando arquivos

node -v > .nvmrc

cat << EOF > .eslintrc.json
{
  "env": {
    "node": true,
    "es2021": true
  },
  "extends": ["standard"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {}
}
EOF

cat << EOF > .gitignore
node_modules
.env
EOF

cat << EOF > .vscode/extensions.json 
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "wayou.vscode-todo-highlight"
  ],
  "unwantedRecommendations": [
    "hookyqr.beautify",
    "dbaeumer.jshint",
    "ms-vscode.vscode-typescript-tslint-plugin"
  ]
}
EOF

cat << EOF > .vscode/settings.json
{
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.tabSize": 2,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[prisma]": {
    "editor.defaultFormatter": "Prisma.prisma",
    "editor.formatOnSave": true
  }
}
EOF

npx prisma init

cat << EOF > src/prismaClient.js
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default prisma
EOF

cat << EOF > src/app.js
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import whitelist from './whitelist.js'

const app = express()

app.use(express.urlencoded({ limit: '25mb', extended: true }))
app.use(express.json({ limit: '25mb', extended: true }))

const corsOptions = {
  origin: function (origin, callback) {
    if (whitelist.indexOf(origin) !== -1 || !origin) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  }
}

app.use(cors())
app.use(helmet())
app.use(cors(corsOptions))

app.get('/', (req, res) => {
  res.send('Olá')
})

EOF

cat << EOF > src/server.js
import { app } from '../app.js'

const PORT = process.env.PORT || 5000
app.listen(PORT, () => console.log('Servidor rodando na porta 5000'))
EOF

cat << EOF > src/whitelist.js
export default [
  'http://localhost:5000'
]
EOF

cat << EOF > vitest.config.js
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {}
})

EOF

cat << EOF > vitest.e2e.config.js
import { defineConfig, mergeConfig } from 'vitest/config'
import vitestConfig from './vitest.config.js'

export default mergeConfig(
  vitestConfig,
  defineConfig({
    test: {
      include: ['**/*.e2e.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
      environmentMatchGlobs: [['src/**', 'prisma']]
    }
  })
)


EOF

cat << EOF > vitest.unit.config.js
import { configDefaults, defineConfig, mergeConfig } from 'vitest/config'
import vitestConfig from './vitest.config.js'

export default mergeConfig(
  vitestConfig,
  defineConfig({
    test: {
      exclude: [...configDefaults.exclude, '**/*.e2e-{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}']
    }
  })
)

EOF

mkdir  prisma/vitest-environment-prisma

cat << EOF > prisma/vitest-environment-prisma/package.json
{
  "name": "vitest-environment-prisma",
  "version": "1.0.0",
  "description": "",
  "main": "prisma-test-environment.js",
  "keywords": [],
  "author": "",
  "license": "ISC"
}

EOF

cat << EOF > prisma/vitest-environment-prisma/vitest-environment-prisma.js
import 'dotenv/config'
import { randomUUID } from 'node:crypto'
import { PrismaClient } from '@prisma/client'
import { execSync } from 'node:child_process'

const prisma = new PrismaClient()

function generateDataBaseUrl (schema) {
  if (!process.env.DATABASE_URL) {
    throw new Error('please provide a database environment variable')
  }

  const url = new URL(process.env.DATABASE_URL)

  url.searchParams.set('schema', schema)

  return url.toString()
}

export default {
  name: 'prisma',
  transformMode: 'ssr',

  async setup () {
    const schema = randomUUID()
    const databaseUrl = generateDataBaseUrl(schema)

    process.env.DATABASE_URL = databaseUrl

    execSync('npx prisma migrate deploy')

    return {
      async teardown () {
        await prisma.\$executeRawUnsafe(\`DROP SCHEMA IF EXISTS "\${schema}" CASCADE\`)
        await prisma.\$disconnect()
      }
    }
  }
}


EOF

#!/bin/bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

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
    "test": "vitest run --dir src/services",
    "test:watch": "vitest --dir src/services",
    "pretest:e2e": "npm run test:create-prisma-environment && npm run test:install-prisma-environment",
    "test:e2e": "vitest run --dir src/http/controllers",
    "test:e2e:watch": "vitest --dir src/http/controllers",
    "test:coverage": "vitest run --coverage"
  },
  "keywords": [],
  "license": "ISC"
}
EOF

echo instalando dependencias 

npm i cors express helmet jsonwebtoken dotenv express-async-errors uuid

npm i -D eslint eslint-config-standard eslint-plugin-import eslint-plugin-n eslint-plugin-promise vitest supertest nodemon prisma

npx prisma init

mkdir prisma/vitest-environment-prisma
mkdir test
mkdir .vscode
mkdir src
mkdir src/auth
mkdir src/http
mkdir src/errors
mkdir src/http/controllers
mkdir src/http/middlewares


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

import { appRouter } from './http/routes.js'

export const app = express()

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

appRouter(app)
EOF

cat << EOF > src/server.js
import { app } from './app.js'

const PORT = process.env.PORT || 5000
app.listen(PORT, () => console.log('Servidor rodando na porta 5000'))
EOF

cat << EOF > src/whitelist.js
export default [
  'http://localhost:8080'
]
EOF

cat << EOF > vite.config.js
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environmentMatchGlobs: [
      ['src/http/controllers/**', 'prisma']
    ]
  }
})
EOF


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


cat << EOF > src/errors/index.js
class BaseError extends Error {
  constructor (message) {
    super()
    this.message = message
    this.httpCode = 500
  }
}

export class BadRequestError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Sintaxe invalida',
      httpCode: 400
    })
  }
}

export class UnauthorizedError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Usuário não autenticado.',
      httpCode: 401
    })
  }
}

export class ForbiddenError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Você não possui permissão para executar esta ação.',
      httpCode: 403
    })
  }
}

export class NotFoundError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Não foi possível encontrar este recurso no sistema.',
      httpCode: 404
    })
  }
}

export class UnprocessableEntityError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Não foi possível realizar esta operação.',
      httpCode: 422
    })
  }
}

export class TooManyRequestsError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Você realizou muitas requisições recentemente.',
      httpCode: 429
    })
  }
}

export class InternalServerError extends BaseError {
  constructor (message) {
    super({
      message: message || 'Um erro interno não esperado aconteceu.',
      httpCode: 500
    })
  }
}
EOF


cat << EOF > src/http/controllers/exemplo.js
/**
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 */
export async function exemplo (req, res) {
  res.status(200).send({ hello: 'hello world' })
}
EOF


cat << EOF > src/http/routes.js
import { errorHandler } from './middlewares/error-handler.js'
import { exemplo } from './controllers/exemplo.js'

/** @param {import('express').Application} app */
export function appRouter (app) {

  // exemplo de rota
  app.get('/', exemplo)

  // a rota abaixa deve sempre ser a ultima
  app.use(errorHandler)
}
EOF



cat << EOF > src/auth/jwt.js
import pkg from 'jsonwebtoken'
const { sign } = pkg

// mude o valor abaixo para uma chave secreta mais segura
export const secretKey = 'MySecret'

/**
 *  essa função cria um token para o usuário utilizando o id do usuário apenas modifique para seu uso
 *  @param {Object} user
 *  @param {number} user.iduser
 */
export function createToken (user) {
  if (!user) {
    throw new Error('usuario não informado')
  }

  // abaixo é um exemplo de payload sub por padrão recebe o id do usuario
  // você pode adicionar mais informações ao payload
  /** @type {import('jsonwebtoken').JwtPayload} */
  const payload = {
    sub: user.iduser
  }

  const token = sign(payload, secretKey, { expiresIn: '10h' })

  return {
    token
  }
}
EOF

cat << EOF > src/http/middlewares/verify-token.js
import pkg from 'jsonwebtoken'
import { secretKey } from '../../auth/jwt.js'
const { verify } = pkg

/**
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 */
export function verifyToken (req, res, next) {
  const token = req.header('Authorization')

  if (!token) {
    return res.status(401).json({ message: 'Unauthorized: No token provided' })
  }

  try {
    const decoded = verify(token.replace('Bearer ', ''), secretKey)

    // toda vez que um token é verificado, o usuário é colocado no req.user
    // verifique a propriedade req.user.sub para obter o id do usuário logado
    req.user = { ...decoded }

    next()
  } catch (err) {
    return res.status(401).json({ message: 'Unauthorized: Invalid token' })
  }
}
EOF

cat << EOF > src/http/middlewares/error-handler.js
// import { prisma } from '../../prismaClient.js'
// import { v4 as uuidv4 } from 'uuid'

// todo que ocorrer sempre passará por esse enpoint 
// todos os erros devem ser tratados aqui

/**
 * @type {import('express').ErrorRequestHandler}
 */
export async function errorHandler (err, req, res, next) {
  // const uuid = uuidv4()

  // abaixo é um exemplo de estrutura de erro no banco de dados
  // await prisma.errorlog.create({
  //  data: {
  //    errorid: uuid,
  //    errorhttpcode: err?.httpCode || 500,
  //    errorinstance: err.name,
  //    errormessage: err.message,
  //    errorstack: err?.stack
  //  }
  // })

  res.status(err.httpCode || 500).send({ message: err.message })
}
EOF
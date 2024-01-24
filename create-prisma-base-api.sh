#!/bin/bash

cat << EOF > package.json
{
  "name": "projeto",
  "version": "1.0.0",
  "description": "",
  "main": "./dist/index.js",
  "scripts": {
    "start": "node ./dist/index.js",
    "start:dev": "nodemon",
    "build": "babel src -d dist",
    "test": "jest",
    "prisma:push": "prisma db push",
    "prisma:pull": "prisma db pull",
    "postinstall":"npx prisma generate && npm run build"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF

echo instalando dependencias 

npm i cors express helmet jsonwebtoken

npm i -D @babel/cli @babel/core @babel/node @babel/preset-env @babel/types @types/jest eslint eslint-config-standard eslint-plugin-import eslint-plugin-jest eslint-plugin-n eslint-plugin-promise jest nodemon prisma

mkdir src
mkdir -p test/src
mkdir .vscode

echo criando arquivos

node -v > .nvmrc

cat << EOF > .eslintrc.json
{
  "plugins": ["jest"],
  "env": {
    "node": true,
    "es2021": true,
    "jest/globals": true
  },
  "extends": ["standard", "plugin:jest/recommended"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {}
}
EOF

cat << EOF > nodemon.json 
{
  "execMap": {
    "js": "babel-node --extensions \".js\" src/index.js"
  }
}
EOF

cat << EOF > .gitignore
node_modules
.env
dist
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
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "eslint.validate": ["javascript", "javascriptreact", "typescript", "vue"],
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

cat << EOF > .babelrc.json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": {
          "node": "current"
        }
      }
    ]
  ]
}
EOF

npx prisma init

cat << EOF > src/prismaClient.js
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default prisma
EOF

cat << EOF > src/index.js
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import whitelist from './whitelist'

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


app.listen(5000, () => console.log('Servidor rodando na porta 5000'))
EOF

cat << EOF > src/whitelist.js
export default [
  'http://localhost:5000'
]
EOF

echo documentações para ler 

echo https://jestjs.io/pt-BR/
echo https://www.prisma.io/docs

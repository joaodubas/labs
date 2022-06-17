FROM node:14-buster AS build

WORKDIR /home/node/lowdefy

RUN chown node:node /home/node/lowdefy

USER node

COPY --chown=node:node ./lowdefy.yaml ./
COPY --chown=node:node ./pages/ ./pages/

RUN npx lowdefy@3.23.3 build

FROM lowdefy/lowdefy:3.23.3

COPY --from=build --chown=node:node /home/node/lowdefy/.lowdefy/build ./build

# NOTE (jpd): if you have a public directory uncomment the next line
# COPY --chown=node:node ./public/ ./public/

ENTRYPOINT ["node"]
CMD ["./dist/server.js"]

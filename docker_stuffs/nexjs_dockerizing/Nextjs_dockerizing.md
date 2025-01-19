

# Create your nextjs app or refer a complete project.

## Ref DockerFile

```
FROM node:20-alpine as build-stage

WORKDIR /app

COPY package*.json ./

RUN yarn install 

COPY . .

RUN yarn build


FROM nginx:stable-alpine as production-stage

COPY --from=build-stage /app/out/ /usr/share/nginx/html
COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf


EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]

```

## 'Step 1'

For static html build files make sure next.config.mjs (current: nextjs14) must include below line inside like below `const NextCOnfig ={};`

```
const nextConfig = {

    output: 'export'
    
};
export default nextConfig;

```

This will allow to create a folder named "out" with static files those helps in nginx redirection

## 'Step 2'

on the terminal run the build command

    

    yarn build or npm run build

**

## 'Step 4'

**

For nginx congifuration this is official nginx config refer: 
https://nextjs.org/docs/app/building-your-application/deploying/static-exports 

In the official documentation the following root directory is 

`root /var/www/out;`

In this case we will use different if you use this project as a reffer so, make sure your root directory is

`root /usr/share/nginx/html;` > in the nginx_config file


## 'Final Step'

For multistage build with nginx add these 2 line in dockerfile

`COPY --from=build-stage /app/out/ /usr/share/nginx/html`
`COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf`

You must have to have nginx.conf file into your project directory in this case i use official nginx config which is referred on the upper link


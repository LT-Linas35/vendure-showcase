import { VendureConfig } from '@vendure/core';
import 'dotenv/config';
import path from 'path';

const IS_DEV = (process.env.APP_ENV ?? 'prod') === 'dev';
const serverPort = +(process.env.PORT ?? '3000');

export const config: VendureConfig = {
    apiOptions: {
        hostname: process.env.HOST_NAME,
        port: serverPort,
        adminApiPath: 'admin-api',
        shopApiPath: 'shop-api',
        // The following options are useful in development mode,
        // but are best turned off for production for security
        // reasons.
        ...(IS_DEV ? {
            adminApiDebug: true,
            shopApiDebug: true,
        } : {}),
    },
    authOptions: {
        tokenMethod: ['bearer', 'cookie'],
        superadminCredentials: {
            identifier: process.env.SUPERADMIN_USERNAME ?? 'superadmin',
            password: process.env.SUPERADMIN_PASSWORD ?? 'superadmin',
        },
        cookieOptions: {
          secret: process.env.COOKIE_SECRET,
        },
    },
    dbConnectionOptions: {
        type: 'postgres',
        // See the README.md "Migrations" section for an explanation of
        // the `synchronize` and `migrations` options.
        synchronize: process.env.synchronize === 'true',
        migrations: [path.join(__dirname, './migrations/*.+(js|ts)')],
        logging: false,
        database: process.env.DB_NAME,
        schema: process.env.DB_SCHEMA,
        ssl: process.env.DB_CA_CERT ? {
            ca: process.env.DB_CA_CERT,
            rejectUnauthorized: false,
        } : undefined,
        host: process.env.DB_HOST,
        port: +(process.env.DB_PORT ?? '5432'),
        username: process.env.DB_USERNAME,
        password: process.env.DB_PASSWORD,
    },
    // When adding or altering custom field definitions, the database will
    // need to be updated. See the "Migrations" section in README.md.
    paymentOptions: {
        paymentMethodHandlers: [],
    },
};

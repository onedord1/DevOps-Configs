import { options as defaultOptions } from './default.js';
import { selectEnv } from '../modules/util/logger.js';

const env = selectEnv();

export const BASE_URL = 'http://172.17.17.23/bmdsalesbe';
export const SUPER_ADMIN_USERNAME = __ENV.STAGING_SUPER_ADMIN_USERNAME;
export const SUPER_ADMIN_PASSWORD = __ENV.STAGING_SUPER_ADMIN_PASSWORD;
export const options = {
  ...defaultOptions,
  thresholds: {
  },
};
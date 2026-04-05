import * as bcrypt from 'bcrypt';

const BCRYPT_ROUNDS = 10;

/** Bcrypt hashes start with $2a$, $2b$, or $2y$. */
const BCRYPT_PREFIX = /^\$2[aby]\$/;

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, BCRYPT_ROUNDS);
}

export function isPasswordHashed(value: string): boolean {
  return BCRYPT_PREFIX.test(value);
}

export async function comparePassword(
  plain: string,
  hash: string,
): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export const featureFlags = {
  useNewAuth: process.env.NEXT_PUBLIC_FEATURE_NEW_AUTH === 'true',
  useNewChat: process.env.NEXT_PUBLIC_FEATURE_NEW_CHAT === 'true',
} as const;

export type FeatureFlag = keyof typeof featureFlags;

export function isFeatureEnabled(flag: FeatureFlag): boolean {
  // Check rollback flag first (highest priority)
  const rollbackKey = `NEXT_PUBLIC_ROLLBACK_${flag.replace('useNew', '').toUpperCase()}`;
  if (process.env[rollbackKey] === 'true') {
    return false;
  }

  return featureFlags[flag] ?? false;
}

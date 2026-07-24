-- Auth / session hardening.
-- 1) Add account suspension + token-version columns to User.
-- 2) Drop the unused Session table (token invalidation now uses User.tokenVersion).

-- AlterTable
ALTER TABLE "User"
  ADD COLUMN "isSuspended" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "suspendedAt" TIMESTAMP(3),
  ADD COLUMN "tokenVersion" INTEGER NOT NULL DEFAULT 0;

-- DropTable (unused; replaced by User.tokenVersion invalidation)
DROP TABLE "Session";

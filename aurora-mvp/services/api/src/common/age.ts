/** Single source of truth for the 18+ age gate (Master Plan §6, §32). */
export function computeAge(dob: Date, now: Date = new Date()): number {
  let age = now.getFullYear() - dob.getFullYear();
  const m = now.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < dob.getDate())) age--;
  return age;
}

export function isAdult(dob: Date, now: Date = new Date()): boolean {
  return computeAge(dob, now) >= 18;
}

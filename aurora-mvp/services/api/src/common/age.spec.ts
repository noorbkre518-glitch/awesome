import { computeAge, isAdult } from './age';

describe('age gate (18+)', () => {
  const now = new Date('2026-07-23T00:00:00Z');

  it('computes age correctly before birthday', () => {
    expect(computeAge(new Date('2008-12-01'), now)).toBe(17);
  });

  it('computes age correctly after birthday', () => {
    expect(computeAge(new Date('2008-01-01'), now)).toBe(18);
  });

  it('rejects a 17-year-old', () => {
    expect(isAdult(new Date('2009-07-24'), now)).toBe(false);
  });

  it('accepts exactly 18 today', () => {
    expect(isAdult(new Date('2008-07-23'), now)).toBe(true);
  });

  it('accepts an adult', () => {
    expect(isAdult(new Date('1990-05-05'), now)).toBe(true);
  });
});

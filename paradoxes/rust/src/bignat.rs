//! Minimal arbitrary-precision unsigned integer, dependency-free.
//!
//! Lean's `Nat` is a kernel-level bignum, which is what lets `decide` compare
//! the two 59-digit integers of the birthday paradox and carry Parrondo's
//! 1000^50-scaled weights exactly.  Rust's built-in integers stop at `u128`
//! (~3.4e38), so this module supplies the missing arithmetic: little-endian
//! base-2^64 limbs with exactly the operations the paradoxes need.

use std::cmp::Ordering;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BigNat {
    /// Little-endian limbs, no trailing zeros (empty == 0).
    limbs: Vec<u64>,
}

impl BigNat {
    pub fn from_u64(n: u64) -> Self {
        if n == 0 {
            BigNat { limbs: vec![] }
        } else {
            BigNat { limbs: vec![n] }
        }
    }

    fn trim(&mut self) {
        while self.limbs.last() == Some(&0) {
            self.limbs.pop();
        }
    }

    pub fn is_zero(&self) -> bool {
        self.limbs.is_empty()
    }

    /// self * m, with m a machine word.
    pub fn mul_small(&self, m: u64) -> BigNat {
        let mut out = Vec::with_capacity(self.limbs.len() + 1);
        let mut carry: u128 = 0;
        for &l in &self.limbs {
            let v = (l as u128) * (m as u128) + carry;
            out.push(v as u64);
            carry = v >> 64;
        }
        if carry > 0 {
            out.push(carry as u64);
        }
        let mut r = BigNat { limbs: out };
        r.trim();
        r
    }

    pub fn add(&self, other: &BigNat) -> BigNat {
        let (a, b) = if self.limbs.len() >= other.limbs.len() {
            (&self.limbs, &other.limbs)
        } else {
            (&other.limbs, &self.limbs)
        };
        let mut out = Vec::with_capacity(a.len() + 1);
        let mut carry: u128 = 0;
        for i in 0..a.len() {
            let v = a[i] as u128 + *b.get(i).unwrap_or(&0) as u128 + carry;
            out.push(v as u64);
            carry = v >> 64;
        }
        if carry > 0 {
            out.push(carry as u64);
        }
        let mut r = BigNat { limbs: out };
        r.trim();
        r
    }

    /// base^exp with a machine-word base.
    pub fn pow(base: u64, exp: u32) -> BigNat {
        let mut acc = BigNat::from_u64(1);
        for _ in 0..exp {
            acc = acc.mul_small(base);
        }
        acc
    }

    /// Falling factorial n * (n-1) * ... * (n-k+1).
    pub fn falling(n: u64, k: u64) -> BigNat {
        let mut acc = BigNat::from_u64(1);
        for i in 0..k {
            acc = acc.mul_small(n - i);
        }
        acc
    }

    /// (self / d, self % d) for a machine-word divisor.
    fn divmod_small(&self, d: u64) -> (BigNat, u64) {
        let mut out = vec![0u64; self.limbs.len()];
        let mut rem: u128 = 0;
        for i in (0..self.limbs.len()).rev() {
            let cur = (rem << 64) | self.limbs[i] as u128;
            out[i] = (cur / d as u128) as u64;
            rem = cur % d as u128;
        }
        let mut q = BigNat { limbs: out };
        q.trim();
        (q, rem as u64)
    }

    /// Approximate value as f64 (exact until the 53-bit mantissa saturates).
    pub fn to_f64(&self) -> f64 {
        let mut acc = 0.0_f64;
        for &l in self.limbs.iter().rev() {
            acc = acc * 18446744073709551616.0 + l as f64;
        }
        acc
    }

    /// Exact decimal rendering.
    pub fn to_decimal(&self) -> String {
        if self.is_zero() {
            return "0".to_string();
        }
        let mut n = self.clone();
        let mut chunks: Vec<u64> = vec![];
        while !n.is_zero() {
            let (q, r) = n.divmod_small(1_000_000_000_000_000_000);
            chunks.push(r);
            n = q;
        }
        let mut s = format!("{}", chunks.pop().unwrap());
        while let Some(c) = chunks.pop() {
            s.push_str(&format!("{:018}", c));
        }
        s
    }
}

impl PartialOrd for BigNat {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for BigNat {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.limbs.len().cmp(&other.limbs.len()) {
            Ordering::Equal => {
                for i in (0..self.limbs.len()).rev() {
                    match self.limbs[i].cmp(&other.limbs[i]) {
                        Ordering::Equal => continue,
                        o => return o,
                    }
                }
                Ordering::Equal
            }
            o => o,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decimal_roundtrip_small() {
        assert_eq!(BigNat::from_u64(0).to_decimal(), "0");
        assert_eq!(BigNat::from_u64(123456789).to_decimal(), "123456789");
    }

    #[test]
    fn pow_matches_u128() {
        // 365^13 still fits u128; cross-check limb arithmetic against it.
        let mut expect: u128 = 1;
        for _ in 0..13 {
            expect *= 365;
        }
        assert_eq!(BigNat::pow(365, 13).to_decimal(), expect.to_string());
    }

    #[test]
    fn falling_matches_u128() {
        let mut expect: u128 = 1;
        for i in 0..15u128 {
            expect *= 365 - i;
        }
        assert_eq!(BigNat::falling(365, 15).to_decimal(), expect.to_string());
    }

    #[test]
    fn add_and_cmp() {
        let a = BigNat::pow(10, 40);
        let b = BigNat::pow(10, 40).mul_small(2);
        assert!(a < b);
        assert_eq!(a.add(&a), b);
    }
}

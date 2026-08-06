//! Rust translation of the Lean 4 paradox suite (PR #2).
//!
//! Mirrors `paradoxes/lean/Main.lean`: prints each module's demo output
//! (the analogue of Lean's compile-time `#eval` lines) followed by the
//! annotated catalog.  Run the actual verification with `cargo test`.

mod bignat;
mod decision_games;
mod probability;

fn print_catalog(title: &str, entries: &[(&str, &str)]) {
    println!("\n═══ {} ({} entries) ═══", title, entries.len());
    for (name, status) in entries {
        println!("  • {name}");
        println!("      {status}");
    }
}

fn main() {
    println!("PARADOXES — Rust translation of the Lean 4 suite (Probability + DecisionGames)");
    println!("(statuses: VERIFIED (test) = checked by cargo test · IDENTITY (spot-checked) =");
    println!(" Lean proves ∀, Rust samples the schema · DEMO = executed exhibit · NOTE = not");
    println!(" formalized here, and why)\n");

    println!("--- Probability demos (Lean's #eval lines) ---");
    probability::demo();
    println!("\n--- DecisionGames demos ---");
    decision_games::demo();

    let catalogs: Vec<(&str, Vec<(&str, &str)>)> = vec![
        ("Probability & statistics", probability::catalog()),
        ("Decisions, games & economics", decision_games::catalog()),
    ];
    for (title, entries) in &catalogs {
        print_catalog(title, entries);
    }
    let total: usize = catalogs.iter().map(|c| c.1.len()).sum();
    let count = |pfx: &str| -> usize {
        catalogs
            .iter()
            .map(|c| c.1.iter().filter(|e| e.1.starts_with(pfx)).count())
            .sum()
    };
    println!(
        "\n═══ TOTAL: {} entries — {} VERIFIED, {} IDENTITY, {} DEMO, {} NOTE ═══",
        total,
        count("VERIFIED"),
        count("IDENTITY"),
        count("DEMO"),
        count("NOTE")
    );
}

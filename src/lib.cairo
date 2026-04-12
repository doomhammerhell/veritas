// Veritas — Secure commit-reveal blind voting on StarkNet

pub mod governance;
pub mod security;
pub mod veritas_main;

pub use veritas_main::Veritas;
pub use veritas_main::{IVeritas, IVeritasDispatcher, IVeritasDispatcherTrait};

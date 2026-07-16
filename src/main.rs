use herdr_navigator::{is_foreground_process_vim, run_command};

use clap::{Parser, Subcommand};
use colored::Colorize;

use std::env;
use std::process::Command;

macro_rules! error {
    ($($args:tt)*) => {
        {
            eprintln!(
                "{} {}",
                "error:".red().bold(),
                format_args!($($args)*),
            );
            std::process::exit(1);
        }
    };
}

#[derive(Parser, Debug)]
#[command(
    name = "herdr-navigator",
    version,
    about = "Cli for a herdr-navigator Neovim plugin for handling Neovim-Herdr pane navigation"
)]
struct Cli {
    #[command(subcommand)]
    direction: Direction,
}

#[derive(Subcommand, Debug, Clone)]
enum Direction {
    Left {
        #[arg(short, long, default_value = "ctrl+h")]
        key: String,
    },
    Right {
        #[arg(short, long, default_value = "ctrl+l")]
        key: String,
    },
    Up {
        #[arg(short, long, default_value = "ctrl+k")]
        key: String,
    },
    Down {
        #[arg(short, long, default_value = "ctrl+j")]
        key: String,
    },
}

impl Direction {
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Left { .. } => "left",
            Self::Right { .. } => "right",
            Self::Up { .. } => "up",
            Self::Down { .. } => "down",
        }
    }

    pub fn key(&self) -> &str {
        match self {
            Self::Left { key }
            | Self::Right { key }
            | Self::Up { key }
            | Self::Down { key } => key,
        }
    }
}

fn main() {
    let cli = Cli::parse();

    let is_vim = match is_foreground_process_vim() {
        Ok(is_vim) => is_vim,
        Err(e) => error!("{e}"),
    };

    let cmd_res = if is_vim {
        let Some(pane_id) = env::var_os("HERDR_ACTIVE_PANE_ID") else {
            error!("cannot read HERDR_ACTIVE_PANE_ID");
        };
        run_command(
            Command::new("herdr")
                .arg("pane")
                .arg("send-keys")
                .arg(pane_id)
                .arg(cli.direction.key()),
        )
    } else {
        run_command(
            Command::new("herdr")
                .arg("pane")
                .arg("focus")
                .arg("--direction")
                .arg(cli.direction.as_str())
                .arg("--current"),
        )
    };
    if let Err(e) = cmd_res {
        error!("{e}");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[test]
    fn verify_cli() {
        Cli::command().debug_assert();
    }
}

#![allow(clippy::option_if_let_else)]

use lazy_regex::regex;

use std::io;
use std::process::{self, Command};

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("{0}")]
    Io(#[from] io::Error),
    #[error("herdr: {0}")]
    Herdr(#[from] HerdrError),
}

#[derive(thiserror::Error, Debug)]
pub enum HerdrError {
    #[error("{0}")]
    InvalidJson(#[from] serde_json::Error),
    #[error("got unexpected JSON")]
    UnexpectedJson,
    #[error("{msg}", msg = other_herdr_error_msg(.0))]
    Other(process::Output),
}

fn other_herdr_error_msg(output: &process::Output) -> String {
    let code_msg = match output.status.code() {
        Some(code) => format!("command exited with code: {code}"),
        None => "command was terminated by a signal".to_string(),
    };
    if output.stderr.is_empty() {
        code_msg
    } else {
        format!("{code_msg}: {}", String::from_utf8_lossy(&output.stderr))
    }
}

fn is_vim(name: &str) -> bool {
    let re = regex!(r"^g?(view|l?n?vim?x?|fzf)(diff)?$");
    re.is_match(name)
}

pub fn run_command(cmd: &mut Command) -> Result<Vec<u8>, Error> {
    let output = cmd.output()?;
    if output.status.success() {
        Ok(output.stdout)
    } else {
        Err(HerdrError::Other(output).into())
    }
}

fn foreground_processes() -> Result<serde_json::Value, Error> {
    let stdout = run_command(
        Command::new("herdr")
            .arg("pane")
            .arg("process-info")
            .arg("--current"),
    )?;
    let mut json: serde_json::Value =
        serde_json::from_slice(&stdout).map_err(HerdrError::InvalidJson)?;
    let processes = json
        .pointer_mut("/result/process_info/foreground_processes")
        .map(serde_json::Value::take)
        .ok_or(HerdrError::UnexpectedJson)?;
    Ok(processes)
}

pub fn is_foreground_process_vim() -> Result<bool, Error> {
    let processes = foreground_processes()?;
    let names = processes
        .as_array()
        .ok_or(HerdrError::UnexpectedJson)?
        .iter()
        .map(|v| {
            v.as_object()
                .and_then(|obj| obj.get("name"))
                .and_then(|v| v.as_str())
        });
    for name in names {
        let Some(name) = name else {
            return Err(HerdrError::UnexpectedJson.into());
        };
        if is_vim(name) {
            return Ok(true);
        }
    }
    Ok(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_vim() {
        #[rustfmt::skip]
        let yes = [
            // core view and fzf
            "view", "gview", "fzf", "gfzf",
            // core vi/vim variants
            "vi", "vim", "vix", "vimx", "gvi", "gvim", "gvix", "gvimx",
            // nvim variants
            "nvi", "nvim", "nvix", "nvimx", "gnvi", "gnvim", "gnvix", "gnvimx",
            // lvim variants
            "lvi", "lvim", "lvix", "lvimx", "glvi", "glvim", "glvix", "glvimx",
            // lnvim variants
            "lnvi", "lnvim", "lnvix", "lnvimx", "glnvi", "glnvim", "glnvix", "glnvimx",
            // diff variants
            "vimdiff", "nvimdiff", "gvimdiff", "viewdiff", "fzfdiff", "lvimdiff",
        ];
        #[rustfmt::skip]
        let no = [
            // close but incorrect prefix/suffix
            "nview", "fzf-tmux", "neovim", "myvim", "vims", "vim2", "svim",
            // substring matches that shouldn't match due to anchors
            "avim", "vima", "xnvim", "nvim-wrapped",
            // random things
            "bash", "zsh", "tmux", "herdr", "nano", "hx", "emacs",
        ];

        for name in yes {
            assert!(
                is_vim(name),
                "Expected '{}' to be recognized as a vim name",
                name
            );
        }
        for name in no {
            assert!(
                !is_vim(name),
                "Expected '{}' to NOT be recognized as a vim name",
                name
            );
        }
    }
}

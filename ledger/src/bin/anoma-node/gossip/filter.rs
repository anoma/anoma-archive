use std::path::Path;

use anoma::protobuf::types::{Filter, Intent};
use thiserror::Error;

use crate::vm;

#[derive(Error, Debug)]
pub enum Error {
    #[error("error while running the filter: {0}")]
    RunnerError(vm::Error),
    #[error("Failed to read file: {0}")]
    FileFailed(std::io::Error),
}

pub type Result<T> = std::result::Result<T, Error>;

pub trait FilterValidate {
    fn from_file(path: impl AsRef<Path>) -> Result<Filter>;

    fn validate(&self, intent: &Intent) -> Result<bool>;
}

impl FilterValidate for Filter {
    fn from_file(path: impl AsRef<Path>) -> Result<Filter> {
        Ok(Filter {
            code: std::fs::read(path).map_err(Error::FileFailed)?,
        })
    }

    fn validate(&self, intent: &Intent) -> Result<bool> {
        let filter_runner = vm::FilterRunner::new();
        filter_runner
            .run(self.code.clone(), &intent.data)
            .map_err(Error::RunnerError)
    }
}

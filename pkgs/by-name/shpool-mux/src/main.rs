use std::env;
use std::fs::OpenOptions;
use std::os::unix::process::CommandExt;
use std::path::PathBuf;
use std::process::Command;

use rustix::fs::{FlockOperation, flock};
use rustix::io::{FdFlags, fcntl_setfd};

fn main() {
    let runtime_dir = env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".to_string());
    let user = env::var("USER").unwrap_or("user".into());
    let lock_dir = PathBuf::from(runtime_dir).join(format!("shpool-{}-locks", user));

    if !lock_dir.exists() {
        std::fs::create_dir_all(&lock_dir).expect("Failed to create lock dir");
    }

    for i in 1..=20 {
        let lock_path = lock_dir.join(format!("slot_{}.lock", i));
        let session_name = format!("{}", i);

        // Open + Create
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(&lock_path);

        if let Ok(f) = file {
            match flock(&f, FlockOperation::NonBlockingLockExclusive) {
                Ok(_) => {
                    // clear CLOEXEC
                    if let Err(e) = fcntl_setfd(&f, FdFlags::empty()) {
                        eprintln!("Failed to clear FD_CLOEXEC: {}", e);
                        continue;
                    }

                    let _ = Command::new("shpool")
                        .arg("attach")
                        .arg("-f")
                        .arg(&session_name)
                        .exec();

                    std::process::exit(1);
                }
                Err(_) => {
                    continue;
                }
            }
        }
    }
    eprintln!("Error: All 20 session slots are occupied.");
    let _ = std::io::stdin().read_line(&mut String::new());
}

use rustix::fs::{FlockOperation, flock};
use rustix::io::{FdFlags, fcntl_setfd};
use std::env;
use std::fs::OpenOptions;
use std::os::unix::process::CommandExt;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let runtime_dir = env::var("XDG_RUNTIME_DIR").unwrap();

    let user = env::var("USER").unwrap_or_else(|_| "user".into());

    let lock_dir = PathBuf::from(&runtime_dir).join(format!("shpool-{}-locks", user));

    // eprintln!("[shpool-mux] Checking Lock Dir: {:?}", lock_dir);

    if !lock_dir.exists() {
        if let Err(e) = std::fs::create_dir_all(&lock_dir) {
            eprintln!("[shpool-mux] FATAL: Failed to create lock dir: {}", e);
            std::process::exit(1);
        }
    }

    for i in 1..=20 {
        let lock_path = lock_dir.join(format!("slot_{}.lock", i));
        let session_name = format!("{}", i);
        let file_result = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(&lock_path);

        match file_result {
            Ok(f) => match flock(&f, FlockOperation::NonBlockingLockExclusive) {
                Ok(_) => {
                    if let Err(e) = fcntl_setfd(&f, FdFlags::empty()) {
                        eprintln!("[shpool-mux] Slot {}: fcntl failed: {}", i, e);
                        continue;
                    }

                    // eprintln!("[shpool-mux] Acquired slot {}, executing...", i);

                    let err = Command::new("shpool")
                        .arg("attach")
                        .arg("-f")
                        .arg(&session_name)
                        .exec();

                    panic!("[shpool-mux] FATAL: Failed to exec shpool: {}", err);
                }
                Err(rustix::io::Errno::WOULDBLOCK) => continue,
                Err(e) => eprintln!("[shpool-mux] Slot {}: Lock error: {}", i, e),
            },
            Err(e) => {
                eprintln!(
                    "[shpool-mux] Slot {}: Failed to open/create file {:?}: {}",
                    i, lock_path, e
                );
            }
        }
    }

    eprintln!("\n[shpool-mux] Error: All 20 slots failed to acquire.");
    eprintln!("Press ENTER to exit...");
    let _ = std::io::stdin().read_line(&mut String::new());
}

use std::io;

fn main() -> io::Result<()> {
    let mut q = nfq::Queue::open()?;
    println!("Ready to bind");
    q.bind(8)?;

    Ok(())
}

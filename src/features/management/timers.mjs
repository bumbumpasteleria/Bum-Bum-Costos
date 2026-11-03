export function remaining(timer,now){return timer.paused?timer.left:Math.max(0,timer.ends-now)}

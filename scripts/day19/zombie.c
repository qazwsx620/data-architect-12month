/* Day19 演示：僵尸进程稳定复现（C 语言 fork）
 * 编译：gcc zombie.c -o zombie
 * 运行：./zombie &    （等待 3 秒后）
 * 观察：ps aux | grep defunct  状态 Z，<defunct>
 * 处理：ps -ef | grep zombie 找父进程 PPID，kill 父进程，僵尸被 init 回收
 */
#include <stdio.h>
#include <unistd.h>

int main()
{
    pid_t pid = fork();
    if (pid > 0) {
        /* 父进程：休眠 20 秒，不 wait 回收子进程 */
        printf("父进程pid=%d, 子进程pid=%d\n", getpid(), pid);
        sleep(20);
    } else if (pid == 0) {
        /* 子进程：立即退出，父进程不回收 -> 变僵尸 */
        printf("子进程马上退出\n");
        return 0;
    }
    return 0;
}

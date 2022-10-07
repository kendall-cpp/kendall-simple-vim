## 概述

在kernel 2.6 中引入的一种任务执行机制——CMWQ（Concurrency Managed Workqueue）, Linux中的Workqueue机制是中断底部半部的一种实现，因为workqueue用一个线程处理多个任务，大大降低了资源开销，是一种通用的任务异步处理手段。

## 为何需要workqueue

workqueue 最核心的思想是分离了任务 (work) 的发布者和执行者。当需要执行任务的时候，构造一个 work，塞进相应的 workqueue，由 workqueue 所绑定的 worker (thread) 去执行。如果任务不重要，我们可以让多种任务共享一个 worker，而无需每种任务都开一个 thread 去处理(n -> 1)；相反如果任务很多很重要，那么我们可以开多个 worker 加速处理(1 -> n)，类似于生产者消费者模型。

在传统的实现中，workqueue 和 worker 的对应关系是二元化的：要么使用 Multi Threaded (MT) workqueue 每个 CPU 一个 worker，要么使用 Single Threaded (ST) workqueue 整个系统只有一个 worker。但即使是通过 MT 每个 CPU 都开一个 worker ，它们相互之间是独立的，在哪个 CPU 上挂入的 work 就只能被那个 CPU 上的 worker 处理，这样当某个 worker 因为处理 work 而阻塞时，位于其他 CPU 上的 worker 只能干着急，这并不是我们所期待的并行。更麻烦的是，它很容易导致死锁，比如有 A 和 B 两个 work，B 依赖于 A 的执行结果，而此时如果 A 和 B 被安排由同一个 worker 来做，而 B 恰好在 A 前面，于是形成死锁。

为了解决这个问题，Tejun Heo 在 2009 年提出了 CMWQ(Concurrency Managed Workqueue) ，于 2.6.36 进入 kernel 。

## Linux中的workqueue机制

```c
struct work_struct {
  atomic_long_t data;
  struct list_head entry;
  work_func_t func;                                                                  
};

 // 工作任务的回调函数类型
 typedef void (*work_func_t)(struct work_struct *work); 
```

- entry 表示所挂载的 workqueue 队列的节点
- func  就是执行的任务的入口函数
- data: 最后 4 个bits 是作为 flags 标志位使用的，中间的 4 个bits是用于 flush 功能的 color （flush 的功能是在销毁 workqueue 队列之前，等待 workqueue 队列上的任务都处理完成）。剩余的存放上一次运行**worker_pool**的 ID 号或 pool_workqueue 的指针。

处理工作任务的工作线程用worker描述，每个worker都 对一个内核线程，worker根据工作状态，可以添加到 worker_pool 的空闲链表和忙碌链表中。处于空闲状态的worker收到工作处理请求之后，就会唤醒 worker 描述的内核线程。

### worker_pool

主要 CPU bound 和 unbound 分为两类。

#### CPU bound worker pool

绑定特定 CPU，其管理的 worker 都运行在该 CPU 上。

根据优先级分为 normal pool 和 high priority pool，后者管理高优先级的 worker。

Linux 会为每个 online CPU 都创建 1 个 normal pool 和 1 个 high priority pool，并在命名上进行区分。

比如 [kworker/1:1] 表示 CPU 1 上 normal pool 的第 1 个 worker ，而 [kworker/2:0H] 表示 CPU 2 上 high priority pool 的第 0 个 worker。

#### unbound

其管理的 worker 可以运行在任意的 CPU 上。

比如 `[kworker/u32:2]` 表示 unbound pool 32 的第 2 个 worker 进程

```c
//[kernel/workqueue_internal.h]
struct worker {
    union {
        /* 如果worker处于idle状态，则将entry挂到worker_pool的idle_list链表中 */
        struct list_head	entry;
        /* 如果worker处于busy状态，则将hentry添加到worker_pool的busy_hash哈希表中 */
        struct hlist_node	hentry;
    };
    struct work_struct	*current_work;	  /* 当前正在处理的工作 */
    work_func_t		current_func;	      /* 当前正在执行的work回调函数 */
    struct pool_workqueue	*current_pwq; /* 当前work所属的pool_workqueue */
    bool			desc_valid;	          /* 字符数组desc是否有效 */
    /* 所有被调度并正准备执行的work都挂入该链表中，只要挂入此链表中的工作任务会被worker处理 */
    struct list_head	scheduled;
    struct task_struct	*task;		      /* 该工作线程的task_struct结构体，调度的实体 */
    struct worker_pool	*pool;		      /* 该工作线程所属的worker_pool */
    struct list_head	node;		      /* 挂到worker_pool->workers链表中 */
    /* 最近一次运行的时间戳，用于判定该工作者线程是否可以被destory时使用 */
    unsigned long		last_active;	  
    unsigned int		flags;		      /* 标志位 */
    int			id;		                  /* 工作线程的ID号，用ps命令在用户空间可以看到具体的值 */
    char			desc[WORKER_DESC_LEN];/* 工作线程的描述说明*/  
    struct workqueue_struct	*rescue_wq;	  
    // 用于调度器确定worker最新的身份
    work_func_t     last_func;   
};
```






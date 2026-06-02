import Testing
import UIKit
@testable import StickerBoard

@Suite("ThumbnailLoadQueue", .serialized)
struct ThumbnailLoadQueueTests {

    // MARK: - 基本動作

    @Test func withSlotはクロージャの戻り値を返す() async {
        let queue = ThumbnailLoadQueue(maxConcurrent: 4)
        let result = await queue.withSlot { 42 }
        #expect(result == 42)
    }

    @Test func withSlotはクロージャがnilを返した場合nilを返す() async {
        let queue = ThumbnailLoadQueue(maxConcurrent: 4)
        let result: Int? = await queue.withSlot { nil }
        #expect(result == nil)
    }

    // MARK: - 同時実行数制限

    @Test func 同時実行数が上限を超えないこと() async {
        let queue = ThumbnailLoadQueue(maxConcurrent: 4)
        let maxObserved = ActorCounter()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    await queue.withSlot {
                        await maxObserved.increment()
                        // 軽量な非同期ポイントで他タスクに実行権を譲る
                        await Task.yield()
                        await maxObserved.decrement()
                    }
                }
            }
        }

        let peak = await maxObserved.peakCount
        #expect(peak <= 4)
    }

    @Test func 上限超過後のタスクはスロット空き後に実行される() async {
        let queue = ThumbnailLoadQueue(maxConcurrent: 2)
        let completedOrder = ActorArray<Int>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                let index = i
                group.addTask {
                    await queue.withSlot {
                        await Task.yield()
                        await completedOrder.append(index)
                    }
                }
            }
        }

        let results = await completedOrder.values
        #expect(results.count == 5)
    }

    // MARK: - キャンセル

    @Test func キャンセルされたタスクはnilを返す() async {
        let queue = ThumbnailLoadQueue(maxConcurrent: 0)  // スロット0で即座に待機
        var result: Int? = -1

        let task = Task {
            result = await queue.withSlot { 99 }
        }
        task.cancel()
        await task.value

        #expect(result == nil)
    }

    @Test func キャンセル後もスロットは正常に解放される() async {
        let queue = ThumbnailLoadQueue(maxConcurrent: 1)

        // 1つ目のタスクでスロットを占有
        let occupyTask = Task {
            await queue.withSlot {
                try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms
            }
        }

        // 少し待ってから2つ目（待機→キャンセル）
        await Task.yield()
        let waitingTask = Task<Int?, Never> {
            await queue.withSlot { 42 }
        }
        waitingTask.cancel()
        await waitingTask.value

        occupyTask.cancel()
        await occupyTask.value

        // キャンセル後にもスロットが取得できること（デッドロックしないこと）
        let result = await queue.withSlot { 1 }
        #expect(result == 1)
    }
}

// MARK: - テスト補助 Actor

private actor ActorCounter {
    private var current = 0
    private(set) var peakCount = 0

    func increment() {
        current += 1
        if current > peakCount { peakCount = current }
    }

    func decrement() {
        current -= 1
    }
}

private actor ActorArray<T: Sendable> {
    private(set) var values: [T] = []

    func append(_ value: T) {
        values.append(value)
    }
}

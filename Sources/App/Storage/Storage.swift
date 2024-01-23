import Vapor
import NIOCore
import NIOConcurrencyHelpers

final class Storage {
    static let shared = Storage()

    func initialize(app: Application) async throws {
        self.app = app
    }

    private var app: Application!
    private let basePath: String = Environment.process.STORAGE_PATH ?? ""
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public func read<C: Decodable>(_ file: String, at path: String = "", type: C.Type) async throws -> C? {
        guard let data = try await self.read(file, at: path) else {
            return nil
        }

        return try self.decoder.decode(C.self, from: data)
    }

    public func read(_ file: String, at path: String = "") async throws -> ByteBuffer? {
        let fullPath = self.basePath + path + file
        print("Reading file: \(fullPath)")
        if FileManager.default.fileExists(atPath: fullPath) {
            return try await self.collectFile(at: fullPath).get()
        } else {
            print(" - Not found")
            return nil
        }
    }

    public func write(_ content: any Encodable, to file: String, at path: String = "") async throws {
        let data = try self.encoder.encode(content)
        try await self.write(data: ByteBuffer(data: data), to: file, at: path)
    }

    public func write(string: String, to file: String, at path: String = "") async throws {
        try await self.write(data: ByteBuffer(string: string), to: file, at: path)
    }

    public func write(data buffer: ByteBuffer, to file: String, at path: String = "") async throws {
        let folderPath = self.basePath + path
        let fullPath = folderPath + file
        print("Writing file: \(fullPath)")
        try? await self.createDirectory(at: folderPath).get()
        return try await self.writeFile(buffer, at: fullPath).get()
    }
}

extension Storage {
    private var io: NonBlockingFileIO {
        self.app.fileio
    }

    private var allocator: ByteBufferAllocator {
        self.app.allocator
    }

    private func eventLoop() -> EventLoop {
        self.app.eventLoopGroup.next()
    }

    fileprivate func createDirectory(at path: String) -> EventLoopFuture<Void> {
        return self.io.createDirectory(path: path, withIntermediateDirectories: true, mode: 0,
                                       eventLoop: self.eventLoop())
    }

    fileprivate func collectFile(at path: String) -> EventLoopFuture<ByteBuffer> {
        let dataWrapper: NIOLockedValueBox<ByteBuffer> = .init(self.allocator.buffer(capacity: 0))
        return self.readFile(at: path) { new in
            var new = new
            _ = dataWrapper.withLockedValue({ $0.writeBuffer(&new) })
            return self.eventLoop().makeSucceededFuture(())
        }.map { dataWrapper.withLockedValue { $0 } }
    }

    @preconcurrency 
    fileprivate func readFile(
        at path: String,
        chunkSize: Int = NonBlockingFileIO.defaultChunkSize,
        onRead: @Sendable @escaping (ByteBuffer) -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: path),
            let fileSize = attributes[.size] as? NSNumber
        else {
            return self.eventLoop().makeFailedFuture(Abort(.internalServerError))
        }
        return self.read(
            path: path,
            fromOffset: 0,
            byteCount:
            fileSize.intValue,
            chunkSize: chunkSize,
            onRead: onRead
        )
    }

    private func read(
        path: String,
        fromOffset offset: Int64,
        byteCount: Int,
        chunkSize: Int,
        onRead: @Sendable @escaping (ByteBuffer) -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        let eventLoop = self.eventLoop()
        return eventLoop.flatSubmit {
            do {
                let fd = try NIOFileHandle(path: path)
                let fdWrapper = NIOLoopBound(fd, eventLoop: eventLoop)
                let done = self.io.readChunked(
                    fileHandle: fd,
                    fromOffset: offset,
                    byteCount: byteCount,
                    chunkSize: chunkSize,
                    allocator: self.allocator,
                    eventLoop: eventLoop
                ) { chunk in
                    return onRead(chunk)
                }
                done.whenComplete { _ in
                    try? fdWrapper.value.close()
                }
                return done
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }

    fileprivate func writeFile(_ buffer: ByteBuffer, at path: String) -> EventLoopFuture<Void> {
        let eventLoop = self.eventLoop()
        return eventLoop.flatSubmit {
            do {
                let fd = try NIOFileHandle(path: path, mode: .write, flags: .allowFileCreation())
                let fdWrapper = NIOLoopBound(fd, eventLoop: eventLoop)
                let done = self.io.write(fileHandle: fd, buffer: buffer, eventLoop: eventLoop)
                done.whenComplete { _ in
                    try? fdWrapper.value.close()
                }
                return done
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
}

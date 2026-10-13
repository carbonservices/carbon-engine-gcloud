#include "SystemMonitor.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#include <dxgi.h>

// Qt
#include <QMutexLocker>
#include <QThread>
#include <algorithm>

// ─────────────────────────────────────────────────────────────
// Helper: convert a FILETIME to a 64-bit integer
// ─────────────────────────────────────────────────────────────
static quint64 fileTimeToUll(const FILETIME& ft)
{
    ULARGE_INTEGER uli;
    uli.LowPart  = ft.dwLowDateTime;
    uli.HighPart = ft.dwHighDateTime;
    return uli.QuadPart;
}

// ─────────────────────────────────────────────────────────────
SystemMonitor::SystemMonitor(QObject* parent)
    : QObject(parent)
{
    detectGpu();

    // Seed baseline process times so first delta isn't 0/0.
    FILETIME dum1, dum2, k, u;
    if (GetProcessTimes(GetCurrentProcess(), &dum1, &dum2, &k, &u)) {
        _prevProcKernel = fileTimeToUll(k);
        _prevProcUser   = fileTimeToUll(u);
    }
    FILETIME idle, kernel, user;
    if (GetSystemTimes(&idle, &kernel, &user)) {
        _prevSysIdle   = fileTimeToUll(idle);
        _prevSysKernel = fileTimeToUll(kernel);
        _prevSysUser   = fileTimeToUll(user);
    }

    connect(&_timer, &QTimer::timeout, this, &SystemMonitor::sample);
    _timer.start(kSampleIntervalMs);
}

// ─────────────────────────────────────────────────────────────
void SystemMonitor::detectGpu()
{
    // Enumerate DXGI adapters; select the discrete/primary GPU with the highest dedicated VRAM.
    IDXGIFactory* factory = nullptr;
    if (FAILED(CreateDXGIFactory(__uuidof(IDXGIFactory),
                                  reinterpret_cast<void**>(&factory)))) {
        _gpuPresent = false;
        return;
    }

    IDXGIAdapter* adapter = nullptr;
    quint64 maxVram = 0;
    QString bestGpuDesc;
    bool foundGpu = false;

    for (UINT i = 0; SUCCEEDED(factory->EnumAdapters(i, &adapter)); ++i) {
        if (!adapter) continue;
        DXGI_ADAPTER_DESC desc;
        if (SUCCEEDED(adapter->GetDesc(&desc))) {
            // VendorId 0x1414 is the Microsoft Basic Render Driver — skip it.
            if (desc.VendorId != 0x1414) {
                foundGpu = true;
                quint64 vramMb = static_cast<quint64>(desc.DedicatedVideoMemory / (1024 * 1024));
                if (vramMb >= maxVram) {
                    maxVram = vramMb;
                    bestGpuDesc = QString::fromWCharArray(desc.Description);
                }
            }
        }
        adapter->Release();
        adapter = nullptr;
    }
    factory->Release();

    if (foundGpu) {
        _gpuPresent = true;
        _vramTotalMb = maxVram;
        _log.info(QString("GPU detected: %1 (VRAM: %2 MB)").arg(bestGpuDesc).arg(_vramTotalMb));
    } else {
        _gpuPresent = false;
        _vramTotalMb = 0;
    }
}

// ─────────────────────────────────────────────────────────────
void SystemMonitor::sample()
{
    QMutexLocker lock(&_mutex);

    // ── Process CPU ───────────────────────────────────────────
    {
        FILETIME c, e, k, u;
        if (GetProcessTimes(GetCurrentProcess(), &c, &e, &k, &u)) {
            quint64 curK = fileTimeToUll(k);
            quint64 curU = fileTimeToUll(u);
            quint64 dK   = (curK >= _prevProcKernel) ? (curK - _prevProcKernel) : 0ULL;
            quint64 dU   = (curU >= _prevProcUser)   ? (curU - _prevProcUser)   : 0ULL;
            _prevProcKernel = curK;
            _prevProcUser   = curU;
            // Each 100-ns tick == 1 unit; interval is kSampleIntervalMs ms.
            // Normalize across all logical cores so process CPU usage is 0-100%.
            int numCores = (std::max)(1, QThread::idealThreadCount());
            quint64 intervalTicks = static_cast<quint64>(kSampleIntervalMs) * 10000ULL * static_cast<quint64>(numCores);
            double rawPct = (intervalTicks > 0)
                ? (static_cast<double>(dK + dU) / static_cast<double>(intervalTicks)) * 100.0
                : 0.0;
            _cpuPctProcess = (std::min)(100.0, (std::max)(0.0, rawPct));
        }
    }

    // ── System CPU ────────────────────────────────────────────
    {
        FILETIME idle, kernel, user;
        if (GetSystemTimes(&idle, &kernel, &user)) {
            quint64 curIdle   = fileTimeToUll(idle);
            quint64 curKernel = fileTimeToUll(kernel);
            quint64 curUser   = fileTimeToUll(user);
            quint64 dIdle   = (curIdle   >= _prevSysIdle)   ? (curIdle   - _prevSysIdle)   : 0ULL;
            quint64 dKernel = (curKernel >= _prevSysKernel) ? (curKernel - _prevSysKernel) : 0ULL;
            quint64 dUser   = (curUser   >= _prevSysUser)   ? (curUser   - _prevSysUser)   : 0ULL;
            _prevSysIdle   = curIdle;
            _prevSysKernel = curKernel;
            _prevSysUser   = curUser;
            // Kernel includes idle; total = (kernel - idle) + user.
            // Guard against unsigned underflow if dKernel < dIdle.
            quint64 kernelBusy = (dKernel >= dIdle) ? (dKernel - dIdle) : 0ULL;
            quint64 total = kernelBusy + dUser;
            quint64 denom = kernelBusy + dUser + dIdle;
            double rawSys = (denom > 0)
                ? (static_cast<double>(total) / static_cast<double>(denom)) * 100.0
                : 0.0;
            _cpuPctSystem = (std::min)(100.0, (std::max)(0.0, rawSys));
        }
    }

    // ── Process memory ────────────────────────────────────────
    {
        PROCESS_MEMORY_COUNTERS pmc{};
        pmc.cb = sizeof(pmc);
        if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
            _memUsedMbProcess = pmc.WorkingSetSize / (1024ULL * 1024ULL);
        }
    }

    // ── System memory ─────────────────────────────────────────
    {
        MEMORYSTATUSEX ms{};
        ms.dwLength = sizeof(ms);
        if (GlobalMemoryStatusEx(&ms)) {
            _memTotalMbSystem = ms.ullTotalPhys / (1024ULL * 1024ULL);
            _memUsedMbSystem  = (_memTotalMbSystem > ms.ullAvailPhys / (1024ULL * 1024ULL))
                ? _memTotalMbSystem - ms.ullAvailPhys / (1024ULL * 1024ULL)
                : 0;
        }
    }
}

// ─────────────────────────────────────────────────────────────
void SystemMonitor::setEnginePhase(EnginePhase phase)
{
    _phase.store(phase);
    if (phase == EnginePhase::Idle) {
        _tokensPerSec.store(0.0);
    }
}

EnginePhase SystemMonitor::enginePhase() const
{
    return _phase.load();
}

void SystemMonitor::setTokensPerSec(double tps)
{
    _tokensPerSec.store(tps);
}

// ─────────────────────────────────────────────────────────────
double SystemMonitor::cpuPctProcess() const
{
    QMutexLocker lock(&_mutex);
    return _cpuPctProcess;
}

double SystemMonitor::cpuPctSystem() const
{
    QMutexLocker lock(&_mutex);
    return _cpuPctSystem;
}

quint64 SystemMonitor::memUsedMbProcess() const
{
    QMutexLocker lock(&_mutex);
    return _memUsedMbProcess;
}

quint64 SystemMonitor::memUsedMbSystem() const
{
    QMutexLocker lock(&_mutex);
    return _memUsedMbSystem;
}

quint64 SystemMonitor::memTotalMbSystem() const
{
    QMutexLocker lock(&_mutex);
    return _memTotalMbSystem;
}

bool SystemMonitor::gpuPresent() const
{
    return _gpuPresent;
}

quint64 SystemMonitor::vramTotalMb() const
{
    return _vramTotalMb;
}

double SystemMonitor::tokensPerSec() const
{
    return _tokensPerSec.load();
}

// ─────────────────────────────────────────────────────────────
QString SystemMonitor::phaseString(EnginePhase phase)
{
    switch (phase) {
    case EnginePhase::Idle:         return QStringLiteral("Idle");
    case EnginePhase::LoadingModel: return QStringLiteral("Loading model");
    case EnginePhase::Embedding:    return QStringLiteral("Embedding");
    case EnginePhase::Inferencing:  return QStringLiteral("Inferencing");
    case EnginePhase::DbReading:    return QStringLiteral("DB Reading");
    case EnginePhase::DbWriting:    return QStringLiteral("DB Writing");
    }
    return QStringLiteral("Unknown");
}

QJsonObject SystemMonitor::getSystemSnapshot() const
{
    double  cpuProc  = cpuPctProcess();
    double  cpuSys   = cpuPctSystem();
    quint64 memProc  = memUsedMbProcess();
    quint64 memSys   = memUsedMbSystem();
    quint64 memTotal = memTotalMbSystem();
    bool    gpuPres  = gpuPresent();
    double  tps      = tokensPerSec();

    QJsonObject obj;
    obj["cpu_pct_process"]        = qRound(cpuProc * 10.0) / 10.0;
    obj["cpu_pct_system"]         = qRound(cpuSys  * 10.0) / 10.0;
    obj["memory_used_mb_process"] = static_cast<qint64>(memProc);
    obj["memory_used_mb_system"]  = static_cast<qint64>(memSys);
    obj["memory_total_mb_system"] = static_cast<qint64>(memTotal);
    obj["gpu_present"]            = gpuPres;
    obj["vram_total_mb"]          = static_cast<qint64>(vramTotalMb());
    obj["gpu_pct"]                = gpuPres ? QJsonValue(0.0) : QJsonValue(QJsonValue::Null);
    obj["engine_status"]          = phaseString(enginePhase());
    obj["tokens_per_sec"]         = qRound(tps * 10.0) / 10.0;
    return obj;
}

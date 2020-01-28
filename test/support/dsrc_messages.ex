defmodule DSRCMessages do
  def bsm_message() do
    %Kitt.Message.BSM{
      coreData: %Kitt.Message.BSM.CoreData{
        accelSet: %{lat: 2001, long: 2001, vert: -127, yaw: 0},
        accuracy: %{orientation: 65_535, semiMajor: 255, semiMinor: 255},
        angle: 127,
        brakes: %{
          abs: :unavailable,
          auxBrakes: :unavailable,
          brakeBoost: :unavailable,
          scs: :unavailable,
          traction: :unavailable,
          wheelBrakes: []
        },
        elev: 2750,
        heading: 22_000,
        id: 611,
        lat: 402_364_127,
        long: -833_667_351,
        msgCnt: 72,
        secMark: 48_275,
        size: %{length: 530, width: 150},
        speed: 305,
        transmission: :unavailable
      },
      partII: nil,
      regional: nil
    }
  end

  def srm_message() do
    %Kitt.Message.SRM{
      regional: nil,
      requestor: %{
        id: {:entityID, 1},
        position: %{
          heading: 4800,
          position: %{elevation: 1260, lat: 374_230_638, long: -1_221_420_467},
          speed: %{speed: 486, transmisson: :unavailable}
        },
        type: %{hpmsType: :bus, role: :transit}
      },
      requests: [
        %{
          duration: 2000,
          minute: 497_732,
          request: %{
            id: %{id: 1003, region: 0},
            inBoundLane: {:lane, 8},
            outBoundLane: {:lane, 30},
            requestID: 5,
            requestType: :priorityRequest
          },
          second: 18_140
        }
      ],
      second: 48_140,
      sequenceNumber: 2,
      timeStamp: 497_731
    }
  end
end
